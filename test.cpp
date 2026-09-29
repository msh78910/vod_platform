#include <iostream>
#include <pqxx/pqxx>
#include <boost/asio.hpp>

using namespace std;

// (completion handler function)
void do_something(const boost::system::error_code& /*e*/){ 


    cout<< "inside the completion handler function ..." << endl;
}

void do_something_else(const boost::system::error_code& e, boost::asio::steady_timer *t, int * counter){
    if (*counter < 5) {
        t->expires_at(t->expiry()+boost::asio::chrono::seconds(1));
        cout << ++(*counter) << endl;
        t->async_wait(std::bind(do_something_else, boost::asio::placeholders::error , t, counter)); // چرا بی &???
    }
}
int main()
{

    boost::asio::io_context io /* or thread_pool object */; // (a.k.a an execution context)
    cout << "hello " << endl;
    int counter = 0;
    boost::asio::steady_timer t_1 (io, boost::asio::chrono::seconds(5));
    boost::asio::steady_timer t_2 (io, boost::asio::chrono::seconds(7)); // هر دوی اینها در یک بستر اجرا میشن که بتونن باهم I/O کنن
    boost::asio::steady_timer t_3 (io, boost::asio::chrono::seconds(1));

    t_1.async_wait(&do_something);
    t_2.async_wait(&do_something);
    t_3.async_wait(std::bind(do_something_else, boost::asio::placeholders::error , &t_3, &counter)); // حتما & بذارم. حتی اگه کپی میکنه

    cout << "let's run()" << endl;
    io.run();
    cout << "goodbye world!!" << endl;
}