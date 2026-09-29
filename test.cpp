#include <iostream>
#include <pqxx/pqxx>
#include <boost/asio.hpp>

int main()
{

    boost::asio::io_context io; // or thread_pool object
    
    std::cout << "hello " << std::endl;
    boost::asio::steady_timer t(io, boost::asio::chrono::seconds(5));

    t.wait();
    std::cout << "goodbye world" << std::endl;
}