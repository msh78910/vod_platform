cmake_minimum_required(VERSION 4.4.2)
set (ENV{CC} "gcc-13")
set (ENV{CXX} "g++-13")

# project(test)
project(HelloWorld)


# find_package(fmt)
find_package(fmt CONFIG REQUIRED)


add_executable(HelloWorld test.cpp)

target_link_libraries(HelloWorld
    PRIVATE
        # test.cpp
        fmt::fmt
    # PUBLIC
)