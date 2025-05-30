# 项目结构

```bash
lib
├── assets                                      - 静态文件
│   ├── covers                                  -- 应用启动封面
│   ├── icons                                   -- 应用图标
│   ├── pics                                    -- 其他图片资源
│   └── star.jpg                        
├── constants                                   - 属性资源
│   ├── app_colors.dart                         -- 配色
│   ├── app_misc.dart                           -- 杂项
│   ├── app_text_styles.dart                    -- 文本样式
│   └── index.dart                              * 导出脚本
├── l10n                                        - 本地化
│   ├── app_en.arb                              -- 本地化配置
│   ├── app_localization.dart                   -- 本地化（自动生成）
│   ├── app_localization_en.dart                -- 英文
│   ├── app_localization_zh.dart                -- 中文
│   ├── app_zh.arb                              -- 语言翻译
│   └── build           
├── main.dart                                   启动文件
├── models                                      - 组件模型
│   ├── book.dart                               -- 书籍项
│   ├── favorite_item.dart                      -- 收藏的书籍项
│   └── index.dart                              * 导出脚本
├── native                                      - native实现
│   ├── index.dart                              * 导出脚本
│   ├── native_bindings.dart                    -- 接口绑定
│   ├── native_wrapper.dart                     -- 接口包装器
│   └── platform_specific.dart                  -- 不同平台特化
├── screens                                     - 应用界面
│   ├── book_browser                            -- 书籍浏览器
│   │   ├── book_browser_screen.dart            --- 书籍浏览界面
│   │   ├── index.dart                          * 导出脚本
│   │   └── widgets                             --- 书籍浏览器界面组件
│   │       ├── featured_books_section.dart     ---- 特色书籍
│   │       ├── index.dart                      * 导出脚本
│   │       ├── reading_stats_card.dart         ---- 阅读状态
│   │       ├── recently_reading_header.dart    ---- 最近阅读书籍页眉
│   │       ├── recently_reading_list.dart      ---- 最近阅读书籍列表
│   │       ├── search_bar_widget.dart          ---- 搜索栏
│   │       └── section_title_widget.dart       ---- 页面标题
│   ├── book_details                            -- 书籍详情
│   │   └── book_details_screen.dart            --- 书籍详情界面
│   ├── book_favorites                          --- 收藏书籍
│   │   ├── favorite_screen.dart                ---- 收藏的书籍界面
│   │   └── index.dart                          * 导出脚本
│   ├── book_notes                              -- 读书笔记
│   │   ├── book_notes_screen.dart              --- 读书笔记浏览界面
│   │   ├── index.dart                          * 导出脚本
│   │   └── noter.dart                          --- 笔记助手
│   ├── book_reader                             -- 书籍阅读器
│   │   ├── book_reader_screen.dart             --- 书籍阅读界面
│   │   ├── index.dart                          * 导出脚本
│   │   ├── pdf_details_screen.dart             --- 书籍详情界面
│   │   ├── test_http_screen.dart               --- 测试http界面
│   │   └── widgets                             --- 书籍阅读器组件
│   │       ├── add_note_dialog.dart            ---- 添加笔记对话框
│   │       ├── index.dart                      * 导出脚本
│   │       ├── initial_reader_view.dart        ---- 初始化阅读器视图
│   │       ├── pdf_viewer_wrapper.dart         ---- pdf阅读器视图包装器
│   │       ├── reader_app_bar.dart             ---- 阅读器标题栏
│   │       ├── reader_menu_button.dart         ---- 阅读器菜单按钮
│   │       ├── reader_tools_menu.dart          ---- 阅读器菜单
│   │       ├── search_bar_content.dart         ---- 搜索内容
│   │       └── text_selection_menu_items.dart  ---- 文本选择菜单
│   ├── feedback                                -- 用户反馈
│   │   ├── feedback_screen.dart                --- 用户反馈界面
│   │   └── index.dart                          * 导出脚本
│   ├── profile                                 -- 个人配置信息
│   │   ├── index.dart                          --- 导出脚本
│   │   ├── profile_screen.dart                 --- 个人配置信息界面
│   │   └── widgets                             --- 个人配置信息界面
│   │       └── index.dart                      * 导出脚本
│   ├── reading_heatmap                         -- 阅读情况热力图
│   │   └── reading_heatmap_screen.dart         --- 阅读情况热力图界面
│   ├── screen_framework.dart                   -- 应用界面框架
│   └── splash_screen.dart                      -- 启动动画
├── services                                    -- 各个界面功能实现
│   ├── favorite_service.dart                   --- 收藏书籍子功能
│   ├── note_service.dart                       --- 笔记管理子功能
│   ├── reading_time_service.dart               --- 阅读时间管理子功能
│   └── recent_reading_service.dart             --- 最近阅读书籍管理子功能
└── widgets                                     -- 子组件
    ├── book_card.dart                          --- 书籍介绍卡片
    ├── book_reader_builder.dart                --- 书籍阅读器构建器
    ├── bottom_nav.dart                         --- 底部导航栏
    └── index.dart                              * 导出脚本

24 directories, 62 files
```