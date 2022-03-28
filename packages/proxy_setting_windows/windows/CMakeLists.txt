cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "proxy_setting_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

list(APPEND PLUGIN_SOURCES
  "system_apis.cpp"
  "system_apis.h"
  "proxy_setting_plugin.cpp"
  "proxy_setting_plugin.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/proxy_setting_windows/proxy_setting_windows.h"
  "proxy_setting_windows.cpp"
  ${PLUGIN_SOURCES}
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE Winhttp)
# List of absolute paths to libraries that should be bundled with the plugin
set(file_chooser_bundled_libraries
  ""
  PARENT_SCOPE
)