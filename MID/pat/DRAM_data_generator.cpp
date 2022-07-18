#include <fstream>
#include <cmath>
//#define DRAM_SIZE 65536 * 4
#define DRAM_SIZE 65536 * 2
using namespace std;

const char a[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};

int main(){
    srand(888);
    
    ofstream output;
    output.open("dram.dat", ios::out);
    output << endl;

    for (int i = 0; i < DRAM_SIZE; ++i){
        if (i % 4 == 0){
            output << "@" << a[(i / (16 * 16 * 16 * 16)) % 16 + 1] << a[(i / (16 * 16 * 16)) % 16] << a[(i / (16 * 16)) % 16] << a[(i / 16) % 16] << a[i % 16] << endl;
            output << a[rand() % 16] << a[rand() % 16] << ' ';
        }
        else if (i == DRAM_SIZE - 1)
            output << a[rand() % 16] << a[rand() % 16];
        else if (i % 4 == 3)
            output << a[rand() % 16] << a[rand() % 16] << endl;
        else
            output << a[rand() % 16] << a[rand() % 16] << ' ';

    }
}