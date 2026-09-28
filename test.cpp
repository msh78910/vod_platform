#include <iostream>
#include <pqxx/pqxx>

int main()
{
  try
  {
    // Connect to the database.
    pqxx::connection cx("host=localhost port=5432 dbname=vod user=vod_user password='7891078910'");

    // In libpqxx, you always work in transaction. Start it like:
    pqxx::work tx(cx);

    std::string first_name = "ali";
    std::string last_name = "shaeri";
    std::string birthday = "1992-07-18";
    std::string bio = "very good";
    std::string url = "some/where";
    // pqxx::row r = tx.exec("SELECT * from "); //.one_row();
    pqxx::result r = tx.exec("INSERT INTO public.person(first_name, last_name, birth_date, bio, photo_url)"
	          "VALUES ($1, $2, $3, $4, $5)"
            "RETURNING id", pqxx::params{first_name, last_name, birthday, bio, url});
    std::string uuid = r[0][0].as<std::string>();
    
    tx.exec("INSERT INTO public.account(person_id, username, email, password_hash)"
	          "VALUES ($1, $2, $3, $4)", pqxx::params{uuid, "admin", "admin@gmail.com", "78910"});
 
    // Commit your transaction.  If an exception occurred before this point, execution will have left the block, and the
    // transaction will have been destroyed along the way.  
    // In that case, the failed transaction would implicitly abort instead of getting to this point.
    tx.commit();
 
    // "r[0]" returns the first field, which has an "as<...>()" member
    // function template to convert its contents from string to a type you say
    std::cout << "done! " /* r[0].as<int>() */ << std::endl;
  }
  catch (std::exception const &e)
  {
    std::cerr << e.what() << std::endl;
    return 1;
  }
}