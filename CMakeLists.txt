cmake_minimum_required(VERSION 4.4.2)
# set (ENV{CC} "gcc-13")
# set (ENV{CXX} "g++-13")

project(HelloWorld LANGUAGES CXX)  # No CMAKE_languages_COMPILER could be found. "LANGUAGES" must be in uppercase
# به دلیل نوشتن این خط، کامپایلر C اصلا استفاده نمی شه. چون با اینکه اینجا گفتیم که این پروژه فقط از این زبان 
# استفاده خواهد کرد اما در CMakePresets.json کلید CMAKE_C_COMPILER رو مشخص کردیم

set(CMAKE_CXX_STANDARD 20)                  # میگه همه target هامون باید تحت یک ورژن استاندارد زبان build بشن
                                            # البته کار درستی نیست که یک نسخه رو برای همه اجبار کنیم. چون ممکنه packager های قدیمی تر نتونن (4.1)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(fmt CONFIG REQUIRED)
find_package(libpqxx CONFIG REQUIRED)
find_package(boost_asio CONFIG REQUIRED)

# target_precompile_headers(MyApp PRIVATE "MyCommonHeader.h") // با معرفی هدرهای پرتکرار، افزایش چشمگیر سرعت build 

add_executable(Main) # src/main.cpp) # test.cpp)
target_sources(Main
    PRIVATE
        test.cpp
)

target_link_libraries(Main PRIVATE Boost::asio libpqxx::pqxx fmt::fmt)
# target_link_libraries(Main PRIVATE libpqxx::pqxx)
