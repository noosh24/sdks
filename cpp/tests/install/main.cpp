#include <iostream>

#include <noosh24/noosh24.hpp>

int main()
{
    noosh24::Client client{"nsk_install_check", {.base_url = "http://127.0.0.1:9/v1", .max_retries = 0}};
    std::string filter = noosh24::where().eq("category", "Chef's").gt("price", 4.75);
    std::cout << noosh24::version << " " << filter << "\n";
    try {
        (void)client.whoami();
    } catch (const noosh24::ConnectionError&) {
        std::cout << "connection error as expected\n";
        return 0;
    }
    return 1;
}
