#include <iostream>
#include <pqxx/pqxx>
#include <boost/asio.hpp>

using namespace std;

void do_something(const boost::system::error_code& /*e*/){
    cout<< "inside the completion handler function ..." << endl;
}

int main()
{

    boost::asio::io_context io /* or thread_pool object */; // (a.k.a an execution context)
    cout << "hello " << endl;
    boost::asio::steady_timer t_1 (io, boost::asio::chrono::seconds(5));
    boost::asio::steady_timer t_2 (io, boost::asio::chrono::seconds(7)); // هر دوی اینها در یک بستر اجرا میشن که بتونن باهم I/O کنن

    t_1.async_wait(&do_something);
    t_2.async_wait(&do_something);
    
    cout << "let's run()" << endl;
    io.run();
    cout << "goodbye world!!" << endl;
}