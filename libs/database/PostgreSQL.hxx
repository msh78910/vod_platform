// #include <pqxx/pqxx>
// #include <boost/asio.hpp>
#include "Database.hxx"


class PostgreSQL: public Database
{
private:
    /* data */
public:
    PostgreSQL(/* args */);
    
    ~PostgreSQL();
};

PostgreSQL::PostgreSQL(/* args */)
{
}

PostgreSQL::~PostgreSQL()
{
}
