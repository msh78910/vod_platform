cmake_minimum_required(VERSION 4.4.2)
set (ENV{CC} "gcc-13")
set (ENV{CXX} "g++-13")

# project(test)
project(HelloWorld LANGUAGES CXX)  # No CMAKE_languages_COMPILER could be found. "LANGUAGES" must be in uppercase

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(libpqxx CONFIG REQUIRED)


add_executable(Main) # test.cpp)
target_sources(Main
    PRIVATE
        test.cpp
)

target_link_libraries(Main PRIVATE libpqxx::pqxx)
