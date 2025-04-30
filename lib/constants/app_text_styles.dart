

/*** App Text Styles
 *   
 * 
 * 
 */


import 'package:flutter/material.dart';
import 'app_colors.dart';


class app_text_styles {
    static const TextStyle heading = TextStyle( 
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: app_colors.text_primary,
    );

    static const TextStyle section_title = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: app_colors.text_primary,
    );

    static const TextStyle body_text = TextStyle( 
       fontSize: 16,
       color: app_colors.text_primary,
    );

    static const TextStyle caption = TextStyle( 
        fontSize: 14,
        color: app_colors.text_secondary,
    );

    static const TextStyle button = TextStyle( 
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
    );
}
