#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Flutter Build & Deploy Tool (Single File Version with QSettings & Platform Selection)

A PySide6 application to automate Flutter builds for various platforms,
upload the artifact via SFTP, and record the release information in a
PostgreSQL database. Saves configuration using QSettings (excluding passwords).

Dependencies: PySide6, psycopg, paramiko
Install: pip install PySide6 psycopg paramiko
"""

import sys
import os
import subprocess
import time
import threading # subprocess reading runs in the worker thread context
import paramiko
import psycopg # Using psycopg v3 style
import traceback # For detailed error logging
import datetime
import glob # For finding build artifacts using patterns

from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QLineEdit, QPushButton, QFileDialog, QPlainTextEdit,
    QSpinBox, QGroupBox, QStatusBar, QMessageBox, QProgressBar,
    QComboBox # Added QComboBox
)
# Import QSettings and QByteArray for geometry saving/loading
from PySide6.QtCore import QObject, Signal, QThread, Slot, Qt, QSettings, QByteArray
from PySide6.QtGui import QPalette, QColor, QFont # Added QFont

# =============================================================================
# Constants
# =============================================================================

# Platform Definitions: UI Text -> {id, cmd, artifact_pattern, needs_zip, ext, zip_ext}
#   id: Internal identifier, used in database
#   cmd: Platform argument for 'flutter build'
#   artifact_pattern: Relative path from project root to find the artifact(s).
#                     Can include wildcards (*) or be a directory.
#   needs_zip: Boolean, indicates if the output directory should be zipped. (Not implemented yet)
#   ext: Expected final artifact extension (e.g., .apk, .ipa, .zip if needs_zip=True)
#   zip_ext: Extension to use if zipping.
TARGET_PLATFORMS = {
    "Android APK": {
        "id": "android",
        "cmd": "apk",
        "artifact_pattern": "build/app/outputs/flutter-apk/app-release.apk",
        "needs_zip": False,
        "ext": ".apk",
        "zip_ext": ".zip"
    },
    "Android App Bundle": {
        "id": "android", # Same platform ID as APK
        "cmd": "appbundle",
        "artifact_pattern": "build/app/outputs/bundle/release/app-release.aab",
        "needs_zip": False,
        "ext": ".aab",
        "zip_ext": ".zip"
    },
    "iOS App (IPA)": {
        "id": "ios",
        "cmd": "ipa",
        # Note: IPA location might vary based on export options. This is a common pattern.
        # Might need configuration or better detection. Requires build on macOS.
        "artifact_pattern": "build/ios/ipa/*.ipa",
        "needs_zip": False,
        "ext": ".ipa",
        "zip_ext": ".zip"
    },
    "Web Build": {
        "id": "web",
        "cmd": "web",
        # Output is a directory. We might want to zip it.
        "artifact_pattern": "build/web",
        "needs_zip": True, # Set to True if zipping is desired (requires adding zip logic)
        "ext": ".zip", # If needs_zip=True, final artifact is zip
        "zip_ext": ".zip"
    },
    # Add other platforms like Linux, macOS, Windows as needed
    # "Linux Desktop": { ... },
    # "macOS Desktop": { ... },
    # "Windows Desktop": { ... },
}

# Build Environment Platforms (Where the build is executed)
BUILD_PLATFORMS = ["Windows", "macOS", "Linux"]

# Constants for QSettings
ORGANIZATION_NAME = "GeeCodeX"
APPLICATION_NAME = "FlutterReleaser"

# =============================================================================
# Worker Classes (Background Tasks)
# =============================================================================

class ConnectionTestWorker(QObject):
    """Worker to test DB or SFTP connection in a separate thread."""
    result_ready = Signal(bool, str)  # Signal(success, message)

    def __init__(self, config, test_type):
        super().__init__()
        self.config = config
        self.test_type = test_type # 'db' or 'sftp'

    @Slot()
    def run(self):
        """Runs the connection test."""
        if self.test_type == 'db':
            self.test_db()
        elif self.test_type == 'sftp':
            self.test_sftp()
        else:
            self.result_ready.emit(False, "Internal Error: Invalid test type.")

    def test_db(self):
        """Tests PostgreSQL connection."""
        conn = None
        try:
            # Validate required fields
            required = ['db_host', 'db_port', 'db_name', 'db_user', 'db_password']
            if not all(self.config.get(k) for k in required):
                 raise ValueError("Missing one or more PostgreSQL connection details.")

            conn_str = (
                f"dbname='{self.config['db_name']}' "
                f"user='{self.config['db_user']}' "
                f"password='{self.config['db_password']}' "
                f"host='{self.config['db_host']}' "
                f"port={self.config['db_port']}"
            )
            conn = psycopg.connect(conn_str, connect_timeout=5) # 5 second timeout
            # Optional: Run a simple query to ensure permissions
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
            self.result_ready.emit(True, "Database connection successful!")
        except ValueError as e:
            self.result_ready.emit(False, f"Config Error: {e}")
        except psycopg.OperationalError as e:
            # Provide more specific feedback if possible
            msg = f"DB Error: {e}"
            if "password authentication failed" in str(e):
                msg = "DB Error: Password authentication failed."
            elif "database" in str(e) and "does not exist" in str(e):
                 msg = "DB Error: Database does not exist."
            elif "connection refused" in str(e):
                 msg = "DB Error: Connection refused (check host/port/firewall)."
            self.result_ready.emit(False, msg)
        except Exception as e:
            self.result_ready.emit(False, f"DB Unexpected Error: {type(e).__name__}")
        finally:
            if conn:
                conn.close()

    def test_sftp(self):
        """Tests SFTP connection."""
        ssh_client = None
        try:
            # Validate required fields (password OR key path needed)
            required_base = ['sftp_host', 'sftp_port', 'sftp_user']
            if not all(self.config.get(k) for k in required_base):
                raise ValueError("Missing SFTP host, port, or user.")
            if not self.config.get('sftp_password') and not self.config.get('sftp_key_path'):
                 # Allow testing connection without password if key path might be used later
                 pass # Just try connecting, might fail later if key needed

            ssh_client = paramiko.SSHClient()
            ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy()) # Consider WarningPolicy for security

            port = int(self.config['sftp_port'])

            # Handle password or key-based auth
            if self.config.get('sftp_key_path'):
                 key_path = self.config['sftp_key_path']
                 # TODO: Add passphrase handling if key is encrypted
                 private_key = None
                 key_types = [paramiko.RSAKey, paramiko.Ed25519Key, paramiko.ECDSAKey, paramiko.DSSKey]
                 last_exception = None
                 for key_type in key_types:
                     try:
                         private_key = key_type.from_private_key_file(key_path)
                         break # Success
                     except paramiko.SSHException as e:
                         last_exception = e # Store last error in case none work
                     except Exception as e_gen: # Catch generic load errors too
                          last_exception = e_gen
                 if private_key is None:
                      if last_exception:
                           raise last_exception # Raise the last SSHException or file load error
                      else:
                           raise paramiko.SSHException("Could not load private key (unknown issue).")

                 ssh_client.connect(
                     hostname=self.config['sftp_host'], port=port,
                     username=self.config['sftp_user'], pkey=private_key, timeout=10)

            elif self.config.get('sftp_password'):
                 ssh_client.connect(
                     hostname=self.config['sftp_host'], port=port,
                     username=self.config['sftp_user'], password=self.config['sftp_password'], timeout=10)
            else:
                 # If neither password nor key path provided, try connecting without explicit auth
                 ssh_client.connect(
                      hostname=self.config['sftp_host'], port=port,
                      username=self.config['sftp_user'], timeout=10)

            # Try opening SFTP session and listing current directory
            sftp = ssh_client.open_sftp()
            sftp.listdir('.') # Test operation
            sftp.close()

            self.result_ready.emit(True, "SFTP connection successful!")

        except ValueError as e:
            self.result_ready.emit(False, f"Config Error: {e}")
        except paramiko.AuthenticationException:
            self.result_ready.emit(False, "SFTP Error: Authentication failed (check user/pass/key).")
        except paramiko.SSHException as e:
            self.result_ready.emit(False, f"SFTP SSH Error: {e}")
        except FileNotFoundError:
             self.result_ready.emit(False, f"SFTP Error: Private key file not found at specified path.")
        except Exception as e:
            # Catch generic exceptions like PermissionError during key loading
            self.result_ready.emit(False, f"SFTP Unexpected Error: {type(e).__name__}: {e}")
        finally:
            if ssh_client:
                ssh_client.close()


class BuildDeployWorker(QObject):
    """Worker to handle the entire build, upload, and DB update process."""
    output_received = Signal(str)
    upload_progress = Signal(int, int) # bytes_transferred, total_bytes
    step_changed = Signal(str) # e.g., "Building...", "Uploading...", "Updating DB..."
    finished = Signal(bool, str) # success, final_message

    def __init__(self, config):
        super().__init__()
        self.config = config
        self._is_running = True
        self.current_process = None # Store reference to the subprocess

    @Slot()
    def run(self):
        """Execute the build and deploy steps."""
        self._is_running = True
        self.current_process = None
        try:
            # --- Step 1: Flutter Build ---
            if not self._is_running: return
            self.step_changed.emit(f"Building {self.config['target_platform_text']} v{self.config['version_name']}...")
            build_success, artifact_path = self.run_flutter_build()
            if not self._is_running: # Check if cancelled during build
                self.finished.emit(False, "Build cancelled.")
                return
            if not build_success:
                self.finished.emit(False, "Build failed. Check output.")
                return

            # --- Step 1.5: Zip Artifact if needed (e.g., for Web) ---
            # TODO: Implement zipping logic if config['needs_zip'] is True
            # If zipped, update artifact_path to point to the zip file.
            if self.config.get('needs_zip', False):
                self.output_received.emit("Warning: Zipping artifact not yet implemented.")
                # Placeholder: Add zipping code here, update artifact_path
                # Example:
                # zip_success, zip_path = self.zip_artifact(artifact_path)
                # if not zip_success:
                #     self.finished.emit(False, "Failed to zip artifact.")
                #     return
                # artifact_path = zip_path # Use the zip file for upload

            # --- Step 2: SFTP Upload ---
            if not self._is_running: return
            self.step_changed.emit(f"Uploading {os.path.basename(artifact_path)}...")
            upload_success, remote_path = self.upload_via_sftp(artifact_path)
            if not self._is_running: # Check if cancelled during upload
                 self.finished.emit(False, "Upload cancelled.")
                 return
            if not upload_success:
                 # Error message emitted within upload_via_sftp using finished signal
                 return

            # --- Step 3: Database Update ---
            if not self._is_running: return
            self.step_changed.emit("Updating database record...")
            build_ts = datetime.datetime.now(datetime.timezone.utc)
            db_success = self.update_database(remote_path, build_ts)
            if not self._is_running: # Check if cancelled (less likely here)
                 self.finished.emit(False, "Operation cancelled.")
                 return
            if not db_success:
                # Error message emitted within update_database using finished signal
                return

            # --- All Steps Successful ---
            self.finished.emit(True, f"Successfully deployed v{self.config['version_name']} for {self.config['platform']}!")
        except Exception as e:
            self.output_received.emit(f"\n--- UNEXPECTED WORKER ERROR ---")
            self.output_received.emit(f"{type(e).__name__}: {e}")
            self.output_received.emit(traceback.format_exc())
            self.finished.emit(False, f"An unexpected error occurred: {e}")
        finally:
             self._is_running = False
             self.current_process = None # Clear process reference


    def stop(self):
        """Signals the worker to stop processing."""
        self.output_received.emit("\n--- Stop Requested ---")
        self._is_running = False
        # Attempt to terminate the build process if it's running
        process_to_stop = self.current_process # Capture current process
        if process_to_stop and process_to_stop.poll() is None: # Check if running
             self.output_received.emit("Attempting to terminate build process...")
             try:
                 process_to_stop.terminate() # Ask nicely first
                 try:
                     # Wait a short time for termination
                     process_to_stop.wait(timeout=2)
                     self.output_received.emit("Build process terminated.")
                 except subprocess.TimeoutExpired:
                      self.output_received.emit("Build process did not terminate gracefully, killing.")
                      process_to_stop.kill() # Force kill
                      # Ensure it's dead before continuing cleanup
                      process_to_stop.wait(timeout=1)
                      self.output_received.emit("Build process killed.")
             except Exception as e:
                  self.output_received.emit(f"Error terminating process: {e}")


    def run_flutter_build(self):
        """Executes the flutter build command based on selected platform."""
        project_dir = self.config['project_dir']
        platform_cmd = self.config['target_platform_cmd']
        artifact_pattern = self.config['artifact_pattern']
        platform_name = self.config['target_platform_text'] # For logging

        if not os.path.isdir(project_dir):
            self.output_received.emit(f"Error: Project directory not found: {project_dir}")
            return False, None
        if not platform_cmd or platform_cmd == 'unknown':
             self.output_received.emit(f"Error: Invalid or unknown target platform selected.")
             return False, None
        if not artifact_pattern:
             self.output_received.emit(f"Error: No artifact pattern defined for {platform_name}.")
             return False, None

        # --- Construct command ---
        command = ['flutter', 'build', platform_cmd, '--release']
        # Add version args if supported for the platform (often requires pubspec mod)
        # command.extend(['--build-name', self.config['version_name']])
        # command.extend(['--build-number', str(self.config['version_code'])])

        self.output_received.emit(f"Running command: {' '.join(command)}")
        self.output_received.emit(f"In directory: {project_dir}\n---\n")

        try:
            # Store the process object
            self.current_process = subprocess.Popen(
                command,
                cwd=project_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, # Redirect stderr to stdout
                text=True,
                encoding='utf-8',
                errors='replace', # Handle potential encoding issues
                bufsize=1, # Line buffered
                # creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0
            )

            # Read output line by line
            for line in self.current_process.stdout:
                 if not self._is_running: # Check stop flag before processing line
                      self.output_received.emit("...build stopped by request.")
                      if self.current_process.poll() is None:
                           self.stop() # Trigger termination logic
                      return False, None # Indicate failure/cancellation
                 self.output_received.emit(line.strip())
                 QThread.msleep(5) # Small delay for GUI updates

            exit_code = self.current_process.wait()

            if not self._is_running:
                self.output_received.emit("...build process finished after stop request.")
                return False, None

            self.current_process = None
            self.output_received.emit("\n---")

            if exit_code == 0:
                self.output_received.emit(f"Flutter build for {platform_name} completed successfully.")

                # --- Find Artifact using glob ---
                search_path = os.path.normpath(os.path.join(project_dir, artifact_pattern))
                self.output_received.emit(f"Searching for artifact pattern: {search_path}")
                found_artifacts = glob.glob(search_path, recursive=True) # Recursive might be needed for some patterns

                if not found_artifacts:
                    self.output_received.emit(f"Error: Build succeeded but no artifact found matching pattern: {artifact_pattern}")
                    self.output_received.emit("Check build output or the artifact_pattern in TARGET_PLATFORMS.")
                    return False, None

                # Handle multiple matches (e.g., *.ipa) - typically take the first or latest?
                # For simplicity, take the first one found. Could add sorting by mtime.
                # Also handle if the pattern *is* the directory (like for web)
                if len(found_artifacts) > 1:
                     self.output_received.emit(f"Warning: Found multiple artifacts, using the first one: {found_artifacts[0]}")
                     # You might want to sort by modification time here:
                     # found_artifacts.sort(key=os.path.getmtime, reverse=True)

                artifact_abs_path = os.path.normpath(found_artifacts[0])

                if os.path.exists(artifact_abs_path):
                     self.output_received.emit(f"Found artifact: {artifact_abs_path}")
                     return True, artifact_abs_path
                else:
                     # Should not happen if glob found it, but check anyway
                     self.output_received.emit(f"Error: Glob found path but it doesn't exist? Path: {artifact_abs_path}")
                     return False, None

            else:
                self.output_received.emit(f"Flutter build failed with exit code {exit_code}.")
                return False, None

        except FileNotFoundError:
             self.output_received.emit("Error: 'flutter' command not found. Make sure Flutter SDK is in your system's PATH.")
             return False, None
        except Exception as e:
            self.output_received.emit(f"Error running build process: {e}")
            self.output_received.emit(traceback.format_exc())
            self.current_process = None
            return False, None


    def _sftp_progress_callback(self, bytes_transferred, total_bytes):
         """Callback for SFTP upload progress. Raises exception if stopped."""
         if self._is_running: # Check if cancelled during upload
             self.upload_progress.emit(int(bytes_transferred), int(total_bytes))
         else:
             # Use an exception to signal Paramiko to stop the transfer
             raise Exception("Upload cancelled by user signal.")


    # Inside class BuildDeployWorker(QObject):

    def upload_via_sftp(self, local_path):
        """Uploads the artifact via SFTP with a custom remote filename including version code.""" # Docstring updated
        ssh_client = None
        sftp = None
        remote_path = None
        try:
            # --- Configuration and Validation ---
            # Added 'version_code' to required keys check
            required_base = ['sftp_host', 'sftp_port', 'sftp_user', 'sftp_remote_path', 'platform', 'version_name', 'version_code']
            if not all(self.config.get(k) for k in required_base):
                raise ValueError("Missing SFTP host, port, user, remote path, platform, version name, or version code in config.")
            if not self.config.get('sftp_password') and not self.config.get('sftp_key_path'):
                 raise ValueError("SFTP requires either a password or a private key path.")

            # --- Construct New Filename ---
            platform_id = self.config['platform']         # e.g., 'android'
            version_name = self.config['version_name']   # e.g., '0.0.3'
            version_code = self.config['version_code']   # e.g., 2
            _, original_extension = os.path.splitext(local_path)
            safe_version_name = version_name.replace(" ", "_")

            # ***** MODIFIED LINE: Added version_code *****
            new_filename = f"geecodex-{platform_id}-{safe_version_name}-{version_code}{original_extension}"
            # Example output: geecodex-android-0.0.3-2.apk

            # --- Construct Remote Path (Unchanged from previous modification) ---
            ssh_client = paramiko.SSHClient()
            ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            port = int(self.config['sftp_port'])
            remote_dir = self.config['sftp_remote_path'].replace("\\", "/")
            remote_path = f"{remote_dir.rstrip('/')}/{new_filename}"

            self.output_received.emit(f"Target remote path: {remote_path}")

            # --- Connection Logic (Unchanged) ---
            if self.config.get('sftp_key_path'):
                key_path = self.config['sftp_key_path']
                private_key = None
                key_types = [paramiko.RSAKey, paramiko.Ed25519Key, paramiko.ECDSAKey, paramiko.DSSKey]
                last_exception = None
                for key_type in key_types:
                     try:
                         private_key = key_type.from_private_key_file(key_path)
                         break
                     except paramiko.SSHException as e:
                         last_exception = e
                     except Exception as e_gen:
                          last_exception = e_gen
                if private_key is None: raise last_exception if last_exception else paramiko.SSHException("Key load failed")
                ssh_client.connect(hostname=self.config['sftp_host'], port=port,
                                   username=self.config['sftp_user'], pkey=private_key, timeout=20)
            elif self.config.get('sftp_password'):
                ssh_client.connect(hostname=self.config['sftp_host'], port=port,
                                   username=self.config['sftp_user'], password=self.config['sftp_password'], timeout=20)
            else:
                 raise ValueError("Internal Error: No SFTP auth method.")

            sftp = ssh_client.open_sftp()

            # --- Ensure Remote Directory Exists (Unchanged) ---
            try:
                sftp.stat(remote_dir)
                self.output_received.emit(f"Remote directory {remote_dir} found.")
            except FileNotFoundError:
                self.output_received.emit(f"Remote directory {remote_dir} not found, attempting to create...")
                try:
                    sftp.mkdir(remote_dir)
                    self.output_received.emit(f"Created remote directory.")
                except Exception as mkdir_e:
                    self.output_received.emit(f"Error: Failed to create remote directory: {mkdir_e}")
                    self.finished.emit(False, f"Failed to create remote directory: {remote_dir}")
                    return False, None

            # --- Upload logic (Unchanged) ---
            if os.path.isdir(local_path):
                 self.output_received.emit(f"Error: Cannot directly upload directory '{local_path}'. Zipping is required but not implemented.")
                 self.finished.emit(False, "Directory upload without zipping is not supported.")
                 return False, None
            else:
                 self.output_received.emit(f"Uploading {local_path} to {remote_path}...")
                 start_time = time.time()
                 file_size = os.path.getsize(local_path)
                 sftp.put(local_path, remote_path, callback=self._sftp_progress_callback)

                 end_time = time.time()
                 duration = end_time - start_time
                 file_size_mb = file_size / (1024 * 1024)
                 speed = file_size_mb / duration if duration > 0 else 0
                 self.output_received.emit(f"Upload complete ({file_size_mb:.2f} MB in {duration:.2f}s, {speed:.2f} MB/s).")

            # --- Return the NEW remote path (Unchanged) ---
            return True, remote_path

        except Exception as e:
            if "Upload cancelled by user signal" in str(e):
                 self.output_received.emit("Upload cancelled.")
            else:
                 self.output_received.emit(f"SFTP Upload Error: {type(e).__name__}: {e}")
                 self.output_received.emit(traceback.format_exc())
                 self.finished.emit(False, f"SFTP Upload Error: {e}")
            return False, None
        finally:
            if sftp: sftp.close()
            if ssh_client: ssh_client.close()


    # Inside class BuildDeployWorker(QObject):

    def update_database(self, uploaded_package_path, build_timestamp): # Added timestamp argument
        """Updates the app_updates table in PostgreSQL."""
        conn = None
        try:
            # --- Start Validation (Unchanged) ---
            required_keys = ['platform', 'version_name', 'version_code', 'release_notes', 'build_platform']
            missing_keys = [k for k in required_keys if k not in self.config or self.config[k] is None]
            if missing_keys:
                raise ValueError(f"Internal Error: Missing required config keys: {', '.join(missing_keys)}")

            if not self.config.get('version_name'):
                raise ValueError("Missing build information: Version Name cannot be empty.")
            if not self.config.get('platform') or self.config['platform'] == 'unknown':
                 raise ValueError("Missing build information: Target Platform ID is invalid.")
            if not self.config.get('build_platform'):
                 raise ValueError("Missing build information: Build Platform cannot be empty.")
            if not isinstance(self.config.get('version_code'), int) or self.config.get('version_code', 0) <= 0:
                raise ValueError("Missing build information: Version Code must be a positive integer.")
            # --- End Validation ---


            conn_str = (
                f"dbname='{self.config['db_name']}' "
                f"user='{self.config['db_user']}' "
                f"password='{self.config['db_password']}' "
                f"host='{self.config['db_host']}' "
                f"port={self.config['db_port']}"
            )
            conn = psycopg.connect(conn_str)
            conn.autocommit = False # Use transaction

            with conn.cursor() as cur:
                # --- Step 1: Deactivate older versions (No change needed here if logic is correct) ---
                # This still deactivates based on version_name, which might be intended
                # to allow only one *named* version active at a time.
                deactivate_sql = """
                    UPDATE app_updates
                    SET is_active = FALSE
                    WHERE platform = %s AND is_active = TRUE AND version_name <> %s;
                """
                cur.execute(deactivate_sql, (self.config['platform'], self.config['version_name']))
                self.output_received.emit(f"Deactivated {cur.rowcount} older active version(s) for platform '{self.config['platform']}' with different version names.")

                # --- Step 2: Insert or Update the current version ---
                # ***** CORRECTION: Changed ON CONFLICT target *****
                upsert_sql = """
                    INSERT INTO app_updates (
                        platform, version_name, version_code, release_notes,
                        download_url, is_mandatory, is_active, package_path,
                        build_platform, build_timestamp, created_at
                    ) VALUES (
                        %(platform)s, %(version_name)s, %(version_code)s, %(release_notes)s,
                        %(download_url)s, %(is_mandatory)s, %(is_active)s, %(package_path)s,
                        %(build_platform)s, %(build_timestamp)s, CURRENT_TIMESTAMP
                    )
                    ON CONFLICT (platform, version_code) DO UPDATE SET -- <<< CHANGED HERE
                        version_name = EXCLUDED.version_name,           -- Update name if code conflicts
                        release_notes = EXCLUDED.release_notes,
                        download_url = EXCLUDED.download_url,
                        is_mandatory = EXCLUDED.is_mandatory,
                        is_active = EXCLUDED.is_active,
                        package_path = EXCLUDED.package_path,
                        build_platform = EXCLUDED.build_platform,
                        build_timestamp = EXCLUDED.build_timestamp,
                        created_at = CURRENT_TIMESTAMP;
                """
                params = {
                    'platform': self.config['platform'],
                    'version_name': self.config['version_name'],
                    'version_code': self.config['version_code'],
                    'release_notes': self.config['release_notes'],
                    'download_url': self.config.get('download_url'),
                    'is_mandatory': self.config.get('is_mandatory', False),
                    'is_active': True,
                    'package_path': uploaded_package_path,
                    'build_platform': self.config['build_platform'],
                    'build_timestamp': build_timestamp
                }
                cur.execute(upsert_sql, params)
                # Decide if rowcount indicates INSERT or UPDATE (psycopg3 doesn't make it easy)
                # For simplicity, just report success based on lack of exception here.
                self.output_received.emit(f"DB record upserted for v{self.config['version_name']} / code {self.config['version_code']} ({self.config['platform']} built on {self.config['build_platform']}).")

            conn.commit() # Commit transaction
            return True

        except ValueError as e: # Catch validation errors specifically
             self.output_received.emit(f"Database Update Validation Error: {e}")
             self.finished.emit(False, f"DB Validation Error: {e}") # Report specific error
             if conn: conn.rollback(); # Rollback on validation error before connect too
             return False
        except psycopg.Error as e:
            # ***** CORRECTION: Adjusted exception detail access *****
            error_message = str(e) # Get the main message
            sql_state = e.sqlstate if hasattr(e, 'sqlstate') else 'N/A' # Get SQLSTATE safely

            self.output_received.emit(f"Database Error:")
            self.output_received.emit(f"  SQLSTATE: {sql_state}")
            self.output_received.emit(f"  Message: {error_message}")
            # You could try accessing e.diag for more details if needed, checking its existence first
            # if hasattr(e, 'diag') and e.diag:
            #    self.output_received.emit(f"  Detail: {e.diag.message_detail}")
            #    self.output_received.emit(f"  Hint: {e.diag.message_hint}")

            if conn: conn.rollback();
            # Use the extracted error message for the UI feedback
            self.finished.emit(False, f"Database error: {error_message}")
            return False
        except Exception as e:
             # Catch other unexpected errors
             self.output_received.emit(f"Unexpected DB Update Error: {type(e).__name__}: {e}")
             self.output_received.emit(traceback.format_exc())
             if conn: conn.rollback();
             self.finished.emit(False, f"Unexpected DB update error: {e}")
             return False
        finally:
            if conn: conn.close()

# =============================================================================
# Main Window Class
# =============================================================================

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle(f"{APPLICATION_NAME} - {ORGANIZATION_NAME}")
        self.setGeometry(100, 100, 850, 780) # Increased height slightly

        self.worker_thread = None
        self.build_worker = None
        self.test_worker = None # Keep track of test worker

        # Store status label styles
        self.status_ok_style = "color: green; font-weight: bold;"
        self.status_err_style = "color: red; font-weight: bold;"
        self.status_progress_style = "color: blue;"
        self.status_idle_style = "color: gray;"

        # --- Initialize QSettings ---
        QSettings.setDefaultFormat(QSettings.Format.IniFormat) # Force INI for readability
        self.settings = QSettings(ORGANIZATION_NAME, APPLICATION_NAME)

        self.setup_ui()
        self.set_default_build_platform() # Set default build OS after UI setup
        self.load_settings() # Load settings AFTER UI is created and defaults set


    def setup_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)

        # --- Project Selection ---
        project_group = QGroupBox("1. Flutter Project")
        project_layout = QHBoxLayout()
        self.project_path_edit = QLineEdit()
        self.project_path_edit.setPlaceholderText("Select Flutter project directory...")
        self.project_path_edit.setReadOnly(True)
        browse_button = QPushButton("Browse...")
        browse_button.clicked.connect(self.browse_project_dir)
        project_layout.addWidget(QLabel("Project Path:"))
        project_layout.addWidget(self.project_path_edit)
        project_layout.addWidget(browse_button)
        project_group.setLayout(project_layout)
        main_layout.addWidget(project_group)

        # --- Build Configuration ---
        build_config_group = QGroupBox("2. Build Configuration")
        build_config_layout = QVBoxLayout()

        # Platform Selection Layout
        platform_layout = QHBoxLayout()
        platform_layout.addWidget(QLabel("Target Platform:"))
        self.target_platform_combo = QComboBox()
        self.target_platform_combo.addItems(TARGET_PLATFORMS.keys())
        platform_layout.addWidget(self.target_platform_combo, 1) # Stretch

        platform_layout.addWidget(QLabel("Build On:")) # Label for build OS
        self.build_platform_combo = QComboBox()
        self.build_platform_combo.addItems(BUILD_PLATFORMS)
        platform_layout.addWidget(self.build_platform_combo, 0) # No stretch
        build_config_layout.addLayout(platform_layout)


        # Version Name / Code Layout
        version_layout = QHBoxLayout()
        version_layout.addWidget(QLabel("Version Name:"))
        self.version_name_edit = QLineEdit()
        self.version_name_edit.setPlaceholderText("e.g., 1.2.3 (from pubspec.yaml)")
        version_layout.addWidget(self.version_name_edit, 1) # Stretch factor
        version_layout.addWidget(QLabel("Version Code:"))
        self.version_code_spin = QSpinBox()
        self.version_code_spin.setRange(1, 999999)
        self.version_code_spin.setAlignment(Qt.AlignmentFlag.AlignRight)
        version_layout.addWidget(self.version_code_spin, 0) # No stretch
        build_config_layout.addLayout(version_layout)

        # Release Notes
        build_config_layout.addWidget(QLabel("Release Notes:"))
        self.release_notes_edit = QPlainTextEdit()
        self.release_notes_edit.setPlaceholderText("Enter changes for this version (one change per line recommended)...")
        self.release_notes_edit.setFixedHeight(80) # Limit height
        build_config_layout.addWidget(self.release_notes_edit)
        build_config_group.setLayout(build_config_layout)
        main_layout.addWidget(build_config_group)


        # --- Connection Settings ---
        connection_group = QGroupBox("3. Deployment Settings")
        connections_main_layout = QVBoxLayout() # Main layout for this group
        connections_layout = QHBoxLayout() # Layout for DB and SFTP side-by-side

        # DB Settings
        db_sub_group = QGroupBox("PostgreSQL Database")
        db_layout = QVBoxLayout()
        db_layout.addWidget(QLabel("Host:"))
        self.db_host_edit = QLineEdit()
        self.db_host_edit.setPlaceholderText("e.g., localhost or IP")
        db_layout.addWidget(self.db_host_edit)
        db_port_layout = QHBoxLayout()
        db_port_layout.addWidget(QLabel("Port:"))
        self.db_port_edit = QLineEdit("5432") # Default Port
        db_port_layout.addWidget(self.db_port_edit)
        db_layout.addLayout(db_port_layout)
        db_layout.addWidget(QLabel("Database:"))
        self.db_name_edit = QLineEdit()
        db_layout.addWidget(self.db_name_edit)
        db_layout.addWidget(QLabel("User:"))
        self.db_user_edit = QLineEdit()
        db_layout.addWidget(self.db_user_edit)
        db_layout.addWidget(QLabel("Password:"))
        self.db_password_edit = QLineEdit()
        self.db_password_edit.setPlaceholderText("Enter password (not saved)") # Clarify not saved
        self.db_password_edit.setEchoMode(QLineEdit.EchoMode.Password)
        db_layout.addWidget(self.db_password_edit)
        db_layout.addStretch()
        self.db_test_button = QPushButton("Test DB Connection")
        self.db_status_label = QLabel("Status: Idle")
        self.db_status_label.setStyleSheet(self.status_idle_style)
        db_layout.addWidget(self.db_test_button)
        db_layout.addWidget(self.db_status_label)
        db_sub_group.setLayout(db_layout)
        connections_layout.addWidget(db_sub_group)

        # SFTP Settings
        sftp_sub_group = QGroupBox("SFTP Server")
        sftp_layout = QVBoxLayout()
        sftp_layout.addWidget(QLabel("Host:"))
        self.sftp_host_edit = QLineEdit()
        self.sftp_host_edit.setPlaceholderText("e.g., yourserver.com or IP")
        sftp_layout.addWidget(self.sftp_host_edit)
        sftp_port_layout = QHBoxLayout()
        sftp_port_layout.addWidget(QLabel("Port:"))
        self.sftp_port_edit = QLineEdit("22") # Default Port
        sftp_port_layout.addWidget(self.sftp_port_edit)
        sftp_layout.addLayout(sftp_port_layout)
        sftp_layout.addWidget(QLabel("User:"))
        self.sftp_user_edit = QLineEdit()
        sftp_layout.addWidget(self.sftp_user_edit)
        sftp_layout.addWidget(QLabel("Password:"))
        self.sftp_password_edit = QLineEdit()
        self.sftp_password_edit.setPlaceholderText("Enter password (not saved)") # Clarify not saved
        self.sftp_password_edit.setEchoMode(QLineEdit.EchoMode.Password)
        sftp_layout.addWidget(self.sftp_password_edit)
        # TODO: Add Key Path Selection Button/LineEdit
        # self.sftp_key_path_edit = QLineEdit() ... add browse button
        sftp_layout.addWidget(QLabel("Remote Upload Path:"))
        self.sftp_remote_path_edit = QLineEdit()
        self.sftp_remote_path_edit.setPlaceholderText("e.g., /var/www/app_updates/android")
        sftp_layout.addWidget(self.sftp_remote_path_edit)
        sftp_layout.addStretch()
        self.sftp_test_button = QPushButton("Test SFTP Connection")
        self.sftp_status_label = QLabel("Status: Idle")
        self.sftp_status_label.setStyleSheet(self.status_idle_style)
        sftp_layout.addWidget(self.sftp_test_button)
        sftp_layout.addWidget(self.sftp_status_label)
        sftp_sub_group.setLayout(sftp_layout)
        connections_layout.addWidget(sftp_sub_group)

        connections_main_layout.addLayout(connections_layout)
        connection_group.setLayout(connections_main_layout)
        main_layout.addWidget(connection_group)


        # --- Build Output ---
        output_group = QGroupBox("4. Build Output")
        output_layout = QVBoxLayout()
        self.output_edit = QPlainTextEdit()
        self.output_edit.setReadOnly(True)
        self.output_edit.setPlaceholderText("Build process output will appear here...")
        monospace_font = QFont("Monospace")
        monospace_font.setStyleHint(QFont.StyleHint.TypeWriter)
        monospace_font.setPointSize(9)
        self.output_edit.setFont(monospace_font)
        output_layout.addWidget(self.output_edit)
        output_group.setLayout(output_layout)
        main_layout.addWidget(output_group, stretch=1)

        # --- Progress Bar ---
        self.progress_bar = QProgressBar()
        self.progress_bar.setVisible(False)
        self.progress_bar.setTextVisible(True)
        self.progress_bar.setFormat("Uploading... %p%")
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(0)
        main_layout.addWidget(self.progress_bar)


        # --- Control Buttons ---
        control_layout = QHBoxLayout()
        self.start_button = QPushButton("🚀 Start Build & Deploy")
        self.start_button.setStyleSheet("background-color: #4CAF50; color: white; padding: 6px; font-weight: bold;")
        self.cancel_button = QPushButton("⏹️ Cancel")
        self.cancel_button.setStyleSheet("background-color: #f44336; color: white; padding: 6px;")
        self.cancel_button.setEnabled(False)
        control_layout.addWidget(self.start_button)
        control_layout.addWidget(self.cancel_button)
        main_layout.addLayout(control_layout)

        # --- Status Bar ---
        self.status_bar = QStatusBar()
        self.setStatusBar(self.status_bar)
        self.status_bar.showMessage("Ready. Load settings or configure.")

        # --- Connect Signals ---
        self.db_test_button.clicked.connect(self.test_db_connection)
        self.sftp_test_button.clicked.connect(self.test_sftp_connection)
        self.start_button.clicked.connect(self.start_build_deploy)
        self.cancel_button.clicked.connect(self.cancel_operation)

        # Connect target platform change to update placeholder (optional)
        self.target_platform_combo.currentTextChanged.connect(self.update_remote_path_placeholder)


    @Slot()
    def browse_project_dir(self):
        """Opens a dialog to select the Flutter project directory."""
        last_dir = self.settings.value("paths/last_project_dir", os.path.expanduser("~"))
        directory = QFileDialog.getExistingDirectory(self, "Select Flutter Project Directory", last_dir)
        if directory:
            self.project_path_edit.setText(directory)
            self.settings.setValue("paths/last_project_dir", directory) # Save for next time
            self.read_pubspec_info(directory) # Try reading version info


    def read_pubspec_info(self, project_dir):
         """Attempt to read version from pubspec.yaml."""
         pubspec_path = os.path.join(project_dir, 'pubspec.yaml')
         try:
             if os.path.exists(pubspec_path):
                 with open(pubspec_path, 'r', encoding='utf-8') as f:
                     version_found = False
                     for line in f:
                         line_stripped = line.strip()
                         if line_stripped.startswith('version:'):
                             # Be careful splitting - handle comments or complex lines if needed
                             version_line = line_stripped.split('version:', 1)[1].strip().split('#')[0].strip() # Remove comments
                             parts = version_line.split('+')
                             if len(parts) > 0:
                                 self.version_name_edit.setText(parts[0].strip())
                                 version_found = True
                             # Reset code if only name is present or if it's not an int
                             code_val = 1
                             if len(parts) > 1:
                                 try:
                                     code_val = int(parts[1].strip())
                                 except (ValueError, TypeError):
                                     code_val = 1 # Default if parsing fails
                             self.version_code_spin.setValue(code_val)

                             self.status_bar.showMessage(f"Read version {version_line} from pubspec.yaml", 3000)
                             break # Found the version line
                     if not version_found:
                          self.status_bar.showMessage(f"'version:' line not found or invalid in pubspec.yaml", 3000)
                          self.version_name_edit.setText("")
                          self.version_code_spin.setValue(1)
             else:
                  self.status_bar.showMessage(f"pubspec.yaml not found in selected directory.", 3000)
                  self.version_name_edit.setText("")
                  self.version_code_spin.setValue(1)

         except Exception as e:
             self.status_bar.showMessage(f"Error reading pubspec.yaml: {e}", 4000)
             print(f"Error reading pubspec: {traceback.format_exc()}") # Log details
             self.version_name_edit.setText("")
             self.version_code_spin.setValue(1)


    def get_current_config(self, include_build_info=False):
        """Gathers config, maps target platform UI text to internal details."""
        # Use local variable to avoid potential name clash if 'config' passed in
        current_config = { # Connection details read fresh each time
            'db_host': self.db_host_edit.text().strip(),
            'db_port': self.db_port_edit.text().strip() or '5432',
            'db_name': self.db_name_edit.text().strip(),
            'db_user': self.db_user_edit.text().strip(),
            'db_password': self.db_password_edit.text(), # Read password directly
            'sftp_host': self.sftp_host_edit.text().strip(),
            'sftp_port': self.sftp_port_edit.text().strip() or '22',
            'sftp_user': self.sftp_user_edit.text().strip(),
            'sftp_password': self.sftp_password_edit.text(), # Read password directly
            # TODO: Read key path from UI element when added
            'sftp_key_path': None, # Placeholder
            'sftp_remote_path': self.sftp_remote_path_edit.text().strip(),
        }
        if include_build_info:
            target_ui_text = self.target_platform_combo.currentText()
            target_info = TARGET_PLATFORMS.get(target_ui_text, {}) # Get details from our constant map

            current_config.update({
                'project_dir': self.project_path_edit.text().strip(),
                'version_name': self.version_name_edit.text().strip(),
                'version_code': self.version_code_spin.value(),
                'release_notes': self.release_notes_edit.toPlainText().strip(),
                'build_platform': self.build_platform_combo.currentText(), # Where the build runs
                # --- Platform details from map ---
                'platform': target_info.get('id', 'unknown'), # Target platform ID (e.g., 'android') for DB
                'target_platform_text': target_ui_text, # UI text for display/logging
                'target_platform_cmd': target_info.get('cmd', 'unknown'), # Build command part
                'artifact_pattern': target_info.get('artifact_pattern', ''), # Expected output path/dir
                'needs_zip': target_info.get('needs_zip', False), # Whether to zip output
                'ext': target_info.get('ext', '.unknown'), # Final artifact extension
                'zip_ext': target_info.get('zip_ext', '.zip') # Extension if zipped
                # 'download_url': ..., # Maybe add UI field for this? Or construct later.
                # 'is_mandatory': ..., # Maybe add UI checkbox for this? Default False.
            })
        return current_config

    def set_controls_enabled(self, enabled):
        """Enable/disable controls during operations."""
        self.start_button.setEnabled(enabled)
        self.cancel_button.setEnabled(not enabled)
        self.db_test_button.setEnabled(enabled)
        self.sftp_test_button.setEnabled(enabled)

        # Disable/Enable group boxes or specific interactive elements
        # Project Selection Group
        self.project_path_edit.parent().findChild(QPushButton).setEnabled(enabled) # Browse button

        # Build Configuration Group
        build_config_group = self.target_platform_combo.parentWidget().parentWidget() # Find the QGroupBox
        if isinstance(build_config_group, QGroupBox): build_config_group.setEnabled(enabled)
        else: # Fallback if structure changes
             self.target_platform_combo.setEnabled(enabled)
             self.build_platform_combo.setEnabled(enabled)
             self.version_name_edit.setEnabled(enabled)
             self.version_code_spin.setEnabled(enabled)
             self.release_notes_edit.setEnabled(enabled)

        # DB Settings Group
        db_group = self.db_host_edit.parentWidget().parentWidget() # Find the QGroupBox
        if isinstance(db_group, QGroupBox): db_group.setEnabled(enabled)
        # Ensure password can always be entered, even if group is disabled
        self.db_password_edit.setEnabled(True) # Always allow password entry


        # SFTP Settings Group
        sftp_group = self.sftp_host_edit.parentWidget().parentWidget() # Find the QGroupBox
        if isinstance(sftp_group, QGroupBox): sftp_group.setEnabled(enabled)
        # Ensure password can always be entered
        self.sftp_password_edit.setEnabled(True) # Always allow password entry

        # Re-enable test buttons specifically if parent group was disabled
        self.db_test_button.setEnabled(enabled)
        self.sftp_test_button.setEnabled(enabled)


    def run_connection_test(self, test_type):
        """Starts a connection test in a background thread."""
        if self.worker_thread and self.worker_thread.isRunning():
            QMessageBox.warning(self, "Busy", "Another operation is already in progress.")
            return

        config = self.get_current_config() # Gets current values including passwords
        status_label = self.db_status_label if test_type == 'db' else self.sftp_status_label
        button = self.db_test_button if test_type == 'db' else self.sftp_test_button

        # Validate passwords needed for test
        if test_type == 'db' and not config['db_password']:
             QMessageBox.warning(self, "Input Needed", "Please enter the Database Password to test the connection.")
             status_label.setText("Status: Need Password")
             status_label.setStyleSheet(self.status_err_style)
             return
        if test_type == 'sftp' and not config['sftp_password'] and not config['sftp_key_path']:
             # Allow testing connection without password/key if agent auth might work
             self.status_bar.showMessage("Attempting SFTP test without password/key...", 3000)

        status_label.setText("Status: Testing...")
        status_label.setStyleSheet(self.status_progress_style)
        button.setEnabled(False)
        self.status_bar.showMessage(f"Testing {test_type.upper()} connection...")

        self.worker_thread = QThread(self)
        self.test_worker = ConnectionTestWorker(config, test_type)
        # Pass references to UI elements the worker needs to update upon completion
        self.test_worker.button_ref = button
        self.test_worker.status_label_ref = status_label
        self.test_worker.moveToThread(self.worker_thread)
        self.test_worker.result_ready.connect(self.handle_test_result)
        self.worker_thread.started.connect(self.test_worker.run)
        # Cleanup thread and worker when done
        self.test_worker.result_ready.connect(self.worker_thread.quit)
        self.test_worker.result_ready.connect(self.test_worker.deleteLater)
        self.worker_thread.finished.connect(self.worker_thread.deleteLater)
        # Make sure the worker object reference is cleared when thread finishes
        self.worker_thread.finished.connect(self._clear_test_worker_ref)
        self.worker_thread.start()

    @Slot()
    def test_db_connection(self):
        self.run_connection_test('db')

    @Slot()
    def test_sftp_connection(self):
        self.run_connection_test('sftp')

    @Slot()
    def _clear_test_worker_ref(self):
        """Clear worker references after thread finishes."""
        print("Test worker thread finished.")
        self.test_worker = None
        self.worker_thread = None


    @Slot(bool, str)
    def handle_test_result(self, success, message):
        """Updates the status label based on the test result."""
        # Sender is the ConnectionTestWorker
        sender_worker = self.sender()
        if isinstance(sender_worker, ConnectionTestWorker) and hasattr(sender_worker, 'status_label_ref'):
             status_label = sender_worker.status_label_ref
             button = sender_worker.button_ref
             if status_label: # Check if widget still exists
                 status_label.setText(f"Status: {message}")
                 status_label.setStyleSheet(self.status_ok_style if success else self.status_err_style)
             if button: button.setEnabled(True) # Re-enable the button
             self.status_bar.showMessage(f"{sender_worker.test_type.upper()} test finished: {message}", 5000)
        else:
             # This case might happen if the window is closed while test runs
             print("Received test result, but sender or UI element is missing.")
             self.status_bar.showMessage("Received test result from detached worker.", 5000)
             # Try to re-enable buttons generically if they exist
             if hasattr(self, 'db_test_button'): self.db_test_button.setEnabled(True)
             if hasattr(self, 'sftp_test_button'): self.sftp_test_button.setEnabled(True)
        # References are cleared by the _clear_test_worker_ref slot


    @Slot()
    def start_build_deploy(self):
        """Validates input and starts the build/deploy process."""
        if self.worker_thread and self.worker_thread.isRunning():
            QMessageBox.warning(self, "Busy", "Another operation is already in progress.")
            return

        config = self.get_current_config(include_build_info=True)

        # --- Validation ---
        errors = []
        if not config['project_dir'] or not os.path.isdir(config['project_dir']):
            errors.append("Please select a valid Flutter project directory.")
        if config['platform'] == 'unknown' or config['target_platform_cmd'] == 'unknown':
             errors.append("Please select a valid Target Platform.")
        # iOS specific check - Requires macOS build platform
        if config['platform'] == 'ios' and config['build_platform'] != 'macOS':
            errors.append("iOS builds can only be performed on macOS.")
            # We might allow proceeding but warn, or block completely. Blocking is safer.
            # errors.append("Warning: iOS builds require macOS. Proceeding might fail.")

        if not config['version_name'] or not ('.' in config['version_name']): # Basic check
            errors.append("Please enter a valid Version Name (e.g., 1.0.0).")
        if not config['version_code'] > 0:
             errors.append("Please enter a valid Version Code (must be > 0).")

        # Check Release Notes - Warn if empty, but allow proceeding
        if not config['release_notes']:
              reply = QMessageBox.question(self, 'Confirm Empty Notes',
                                         "Release Notes are empty. Continue anyway?",
                                         QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
                                         QMessageBox.StandardButton.No)
              if reply == QMessageBox.StandardButton.No:
                  # Don't add to errors, just return to let user edit
                  self.release_notes_edit.setFocus()
                  return

        # DB/SFTP checks (ensure fields needed for operation are present)
        db_op_fields = ['db_host', 'db_port', 'db_name', 'db_user', 'db_password']
        sftp_op_fields = ['sftp_host', 'sftp_port', 'sftp_user', 'sftp_remote_path']
        sftp_auth_ok = config.get('sftp_password') or config.get('sftp_key_path') # Check password OR key path

        if not all(config.get(k) for k in db_op_fields):
            errors.append("Missing required PostgreSQL details for database update.")
        if not all(config.get(k) for k in sftp_op_fields):
             errors.append("Missing required SFTP details for upload.")
        if not sftp_auth_ok:
             errors.append("Missing SFTP Password (or Key Path - feature pending) for upload.")

        if errors:
            QMessageBox.critical(self, "Input Error", "\n".join(errors))
            return

        # --- Prepare UI for Build ---
        self.output_edit.clear()
        self.set_controls_enabled(False) # Disable controls
        self.start_button.setText("Processing...")
        self.status_bar.showMessage(f"Starting build & deploy for {config['target_platform_text']}...")
        self.db_status_label.setText("Status: Idle")
        self.db_status_label.setStyleSheet(self.status_idle_style)
        self.sftp_status_label.setText("Status: Idle")
        self.sftp_status_label.setStyleSheet(self.status_idle_style)
        self.progress_bar.setValue(0)
        self.progress_bar.setVisible(False)

        # --- Create Worker and Thread ---
        self.worker_thread = QThread(self)
        self.build_worker = BuildDeployWorker(config) # Pass full config
        self.build_worker.moveToThread(self.worker_thread)

        # Connect signals from worker to UI slots
        self.build_worker.output_received.connect(self.append_output)
        self.build_worker.step_changed.connect(self.update_status_message)
        self.build_worker.upload_progress.connect(self.update_progress_bar)
        self.build_worker.finished.connect(self.handle_build_finished)

        # Connect thread signals for lifecycle management
        self.worker_thread.started.connect(self.build_worker.run)
        # Cleanup when finished
        self.build_worker.finished.connect(self.worker_thread.quit)
        self.build_worker.finished.connect(self.build_worker.deleteLater)
        self.worker_thread.finished.connect(self.worker_thread.deleteLater)
        # Ensure worker references are cleared when the thread finishes
        self.worker_thread.finished.connect(self._clear_build_worker_ref)

        self.worker_thread.start()

    @Slot()
    def _clear_build_worker_ref(self):
        """Clear build worker references after thread finishes."""
        print("Build worker thread finished.")
        self.build_worker = None
        self.worker_thread = None
        # Explicitly re-enable cancel button here ONLY if needed,
        # but handle_build_finished should cover control re-enabling normally.
        # self.cancel_button.setEnabled(False)


    @Slot()
    def cancel_operation(self):
        """Requests the running build/deploy worker thread to stop."""
        if self.worker_thread and self.worker_thread.isRunning() and self.build_worker:
            self.status_bar.showMessage("Attempting to cancel operation...")
            self.append_output("\n*** CANCEL REQUESTED BY USER ***\n")
            self.build_worker.stop() # Call the worker's stop method
            self.cancel_button.setEnabled(False) # Disable cancel button immediately
            self.start_button.setText("Cancelling...")
            # Controls will be re-enabled in handle_build_finished after worker confirms stop
        else:
            self.status_bar.showMessage("No operation running to cancel.", 3000)


    @Slot(str)
    def append_output(self, text):
        """Appends text to the output area and ensures visibility."""
        self.output_edit.appendPlainText(text)
        # self.output_edit.ensureCursorVisible() # Scroll to the bottom - can be slow with lots of output
        # Alternative: move cursor to end without forcing scroll unless at bottom
        cursor = self.output_edit.textCursor()
        cursor.movePosition(cursor.MoveOperation.End)
        self.output_edit.setTextCursor(cursor)


    @Slot(str)
    def update_status_message(self, message):
        """Updates the status bar message and controls progress bar visibility."""
        self.status_bar.showMessage(message)
        # Show progress bar specifically during the Upload step
        if "Uploading" in message and not self.progress_bar.isVisible():
             self.progress_bar.setValue(0)
             self.progress_bar.setFormat("Uploading... %p%")
             self.progress_bar.setVisible(True)
        elif "Uploading" not in message and self.progress_bar.isVisible():
             self.progress_bar.setVisible(False)


    @Slot(int, int)
    def update_progress_bar(self, transferred, total):
        """Updates the SFTP upload progress bar based on bytes."""
        if total > 0:
            percent = int((transferred / total) * 100)
            self.progress_bar.setValue(percent)
            # Optionally update format to show bytes/total
            # self.progress_bar.setFormat(f"Uploading {transferred/1024**2:.1f}/{total/1024**2:.1f} MB... %p%")
        else:
             # Indeterminate state if total is 0 (shouldn't happen with SFTP put)
             self.progress_bar.setRange(0, 0) # Makes it show busy indicator
             self.progress_bar.setValue(-1)


    @Slot(bool, str)
    def handle_build_finished(self, success, message):
        """Handles the completion of the build/deploy process."""
        self.status_bar.showMessage(message, 15000) # Show final message longer
        self.set_controls_enabled(True) # Re-enable controls
        self.start_button.setText("🚀 Start Build & Deploy")
        self.progress_bar.setVisible(False)
        self.progress_bar.setRange(0, 100) # Reset range

        # Display result dialog
        if success:
             QMessageBox.information(self, "Operation Successful", message)
        else:
            # Check if it was a cancellation message
            if "cancel" in message.lower():
                 QMessageBox.warning(self, "Operation Cancelled", message)
            else:
                 QMessageBox.critical(self, "Operation Failed", f"{message}\n\nCheck the Build Output for details.")
        # Worker/thread refs are cleared by the _clear_build_worker_ref slot connected to thread.finished

    @Slot(str)
    def update_remote_path_placeholder(self, platform_text):
        """Updates the SFTP remote path placeholder based on selected platform."""
        platform_info = TARGET_PLATFORMS.get(platform_text, {})
        platform_id = platform_info.get('id', 'unknown')
        if platform_id != 'unknown':
            self.sftp_remote_path_edit.setPlaceholderText(f"e.g., /var/www/app_updates/{platform_id}")
        else:
            self.sftp_remote_path_edit.setPlaceholderText("e.g., /var/www/app_updates/platform")


    def set_default_build_platform(self):
        """Sets the Build Platform combo based on the current OS."""
        current_os = sys.platform
        default_platform = "Linux" # Default fallback
        if current_os == "win32":
            default_platform = "Windows"
        elif current_os == "darwin":
            default_platform = "macOS"

        index = self.build_platform_combo.findText(default_platform)
        if index >= 0:
            self.build_platform_combo.setCurrentIndex(index)
        else:
             # Fallback if current OS name isn't in our list exactly
             if self.build_platform_combo.count() > 0:
                 self.build_platform_combo.setCurrentIndex(0)


    # --- QSettings Implementation ---

    def save_settings(self):
        """Save settings using QSettings (excluding passwords)."""
        try:
            print("Saving settings...") # Console feedback
            # Window geometry
            self.settings.setValue("window/geometry", self.saveGeometry())
            self.settings.setValue("window/state", self.saveState())

            # Paths
            self.settings.setValue("paths/project", self.project_path_edit.text())
            # Save directory containing the project path for 'Browse' starting point
            proj_path = self.project_path_edit.text()
            if proj_path and os.path.isdir(os.path.dirname(proj_path)):
                 self.settings.setValue("paths/last_project_dir", os.path.dirname(proj_path))
            elif proj_path and os.path.isdir(proj_path):
                 self.settings.setValue("paths/last_project_dir", proj_path)
            else:
                 self.settings.setValue("paths/last_project_dir", os.path.expanduser("~"))

            # Build Platforms - Use correct widget names
            self.settings.setValue("build/target_platform", self.target_platform_combo.currentText())
            self.settings.setValue("build/build_platform", self.build_platform_combo.currentText())

            # DB Settings (NO PASSWORD)
            self.settings.beginGroup("db")
            self.settings.setValue("host", self.db_host_edit.text())
            self.settings.setValue("port", self.db_port_edit.text())
            self.settings.setValue("name", self.db_name_edit.text())
            self.settings.setValue("user", self.db_user_edit.text())
            self.settings.endGroup()

            # SFTP Settings (NO PASSWORD)
            self.settings.beginGroup("sftp")
            self.settings.setValue("host", self.sftp_host_edit.text())
            self.settings.setValue("port", self.sftp_port_edit.text())
            self.settings.setValue("user", self.sftp_user_edit.text())
            self.settings.setValue("remote_path", self.sftp_remote_path_edit.text())
            # TODO: Save key path if UI added
            # self.settings.setValue("key_path", self.sftp_key_path_edit.text())
            self.settings.endGroup()

            self.settings.sync() # Ensure changes are written
            self.status_bar.showMessage("Settings saved.", 3000)
            print("Settings saved successfully.")

        except Exception as e:
            print(f"Error saving settings: {e}")
            self.status_bar.showMessage(f"Error saving settings: {e}", 5000)


    def load_settings(self):
        """Load saved settings on startup (excluding passwords)."""
        try:
            print("Loading settings...") # Console feedback

            # --- Window Geometry/State ---
            geometry = self.settings.value("window/geometry")
            state = self.settings.value("window/state")
            # Check if loaded values are valid QByteArray before restoring
            if isinstance(geometry, QByteArray) and not geometry.isNull() and not geometry.isEmpty():
                 self.restoreGeometry(geometry)
            if isinstance(state, QByteArray) and not state.isNull() and not state.isEmpty():
                 self.restoreState(state)

            # --- Paths ---
            self.project_path_edit.setText(self.settings.value("paths/project", ""))
            if self.project_path_edit.text(): # If path loaded, try reading pubspec
                 self.read_pubspec_info(self.project_path_edit.text())

            # --- Load Target Platform ---
            saved_target = self.settings.value("build/target_platform")
            if saved_target and self.target_platform_combo.findText(saved_target) >= 0:
                self.target_platform_combo.setCurrentText(saved_target)
                print(f"Target platform loaded: {saved_target}")
            elif self.target_platform_combo.count() > 0:
                self.target_platform_combo.setCurrentIndex(0) # Default to first item if saved not found
                print(f"Target platform defaulted to: {self.target_platform_combo.currentText()}")
            self.update_remote_path_placeholder(self.target_platform_combo.currentText()) # Update placeholder

            # --- Load Build Platform ---
            saved_build = self.settings.value("build/build_platform")
            if saved_build and self.build_platform_combo.findText(saved_build) >= 0:
                 self.build_platform_combo.setCurrentText(saved_build)
                 print(f"Build platform loaded: {saved_build}")
            else:
                 # If not loaded, keep the default set by set_default_build_platform()
                 print(f"Build platform using default: {self.build_platform_combo.currentText()}")


            # --- Load DB Settings (NO PASSWORD) ---
            self.settings.beginGroup("db")
            self.db_host_edit.setText(self.settings.value("host",""))
            self.db_port_edit.setText(self.settings.value("port","5432"))
            self.db_name_edit.setText(self.settings.value("name",""))
            self.db_user_edit.setText(self.settings.value("user",""))
            self.settings.endGroup()
            self.db_password_edit.clear() # Clear password field

            # --- Load SFTP Settings (NO PASSWORD) ---
            self.settings.beginGroup("sftp")
            self.sftp_host_edit.setText(self.settings.value("host",""))
            self.sftp_port_edit.setText(self.settings.value("port","22"))
            self.sftp_user_edit.setText(self.settings.value("user",""))
            self.sftp_remote_path_edit.setText(self.settings.value("remote_path","")) # Correct name
            # TODO: Load key path when UI added
            # self.sftp_key_path_edit.setText(self.settings.value("key_path", ""))
            self.settings.endGroup()
            self.sftp_password_edit.clear() # Clear password field

            self.status_bar.showMessage("Settings loaded. Enter passwords if needed.", 3000)
            print("Settings loaded.")

        except Exception as e:
            print(f"Error loading settings: {e}")
            print(traceback.format_exc()) # Log details
            self.status_bar.showMessage(f"Error loading settings: {e}", 5000)
            # Attempt to set defaults even on error
            try:
                self.set_default_build_platform()
                if self.target_platform_combo.count() > 0:
                    self.target_platform_combo.setCurrentIndex(0)
                self.update_remote_path_placeholder(self.target_platform_combo.currentText())
            except Exception as e_def:
                 print(f"Error setting defaults after load error: {e_def}")

    def closeEvent(self, event):
        """Handle window closing event, save settings first."""
        # Check if a worker thread is running (either build or test)
        if self.worker_thread and self.worker_thread.isRunning():
             reply = QMessageBox.question(self, 'Confirm Exit',
                                         "An operation (build, test) is currently in progress.\n"
                                         "Stopping it might leave things in an inconsistent state.\n\n"
                                         "Do you really want to exit?",
                                         QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
                                         QMessageBox.StandardButton.No)

             if reply == QMessageBox.StandardButton.Yes:
                 print("Attempting to stop worker on exit...")
                 # Try stopping whichever worker might be active
                 if self.build_worker:
                     self.build_worker.stop()
                 elif self.test_worker:
                      # Test worker doesn't have a 'stop', just disconnect?
                      # It should finish quickly anyway.
                      pass
                 # Save settings even if exiting during operation? Risky.
                 # Let's save settings *only* if closing normally.
                 print("Exiting without saving settings due to ongoing operation.")
                 event.accept() # Allow window to close
             else:
                 event.ignore() # Prevent window from closing
        else:
             # No worker running, save settings and close normally
             self.save_settings() # Save settings on normal close
             event.accept()

# =============================================================================
# Main Application Execution
# =============================================================================

if __name__ == "__main__":
    # Set application details for QSettings BEFORE creating QApplication
    QApplication.setOrganizationName(ORGANIZATION_NAME)
    QApplication.setApplicationName(APPLICATION_NAME)
    # Optional: Set application version if needed elsewhere
    # QApplication.setApplicationVersion("1.1.0")

    app = QApplication(sys.argv)

    window = MainWindow()
    window.show()
    sys.exit(app.exec())