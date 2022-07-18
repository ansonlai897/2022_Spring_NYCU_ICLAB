#include <iostream>
#include <iomanip>
#include <fstream>
#include <cstdlib> /* 亂數相關函數 */
#include <ctime>   /* 時間相關函數 */
#include <math.h>
using namespace std;

int main()
{
    /* 固定亂數種子 */
    srand( time(NULL) );

    int berry,medicine,candy,bracer,money_fir,money_sec,money_third,money_forth;
    int stage,type,hp,atk,exp;
/*
    ofstream myfile;
    myfile.open ("example.txt");
    for(int i=0;i<256;i++){
        for(int j=0;j<2;j++){
            myfile << "@" << hex << 65536+i*8+j*4 <<endl;
            if(j == 0){
                berry = rand() % 16;
                medicine = rand() % 16;
                candy = rand() % 16;
                bracer = rand() % 16;
                money = rand() % 65536;

                myfile << hex <<berry<<medicine<<" "<< candy<<bracer<<" "<<money<<endl;
            }
            else{
                stage = rand() % 3;
                type = rand() % 4;
                hp = rand() % 120;
                exp = rand() % 27;

                myfile << hex <<stage<<type<<" "<<hp<<exp<<endl;
            }
        }
    }
    myfile.close();
*/
    ofstream myfile;
    myfile.open ("example.txt");
    for(int i=0;i<256;i++){
        for(int j=0;j<2;j++){
            myfile << "@" << hex << 65536+i*8+j*4 <<endl;
            if(j == 0){
                berry = rand() % 16;
                medicine = rand() % 16;
                candy = rand() % 16;
                bracer = rand() % 16;
                money_fir = rand() % 16;
                money_sec = rand() % 16;
                money_third = rand() % 16;
                money_forth = rand() % 16;


                myfile << hex <<berry<<medicine<<" "<< candy<<bracer<<" "<<money_fir<<money_sec<<" "<<money_third<<money_forth<<endl;
            }
            else{
                stage = rand() % 3 ;
                type = rand() % 5;
                hp = rand() % 120;
                if(type != 4)
                {
                     if(stage == 2)
                        exp = 0;
                    else
                        exp = rand() % 27;

                    if(type == 0 && stage == 0)
                        atk = 63;
                    else if(type == 0 && stage == 1)
                        atk = 94;
                    else if(type == 0 && stage == 2)
                        atk = 123;
                    else if(type == 1 && stage == 0)
                        atk = 64;
                    else if(type == 1 && stage == 1)
                        atk = 96;
                    else if(type == 1 && stage == 2)
                        atk = 127;
                    else if(type == 2 && stage == 0)
                        atk = 60;
                    else if(type == 2 && stage == 1)
                        atk = 89;
                    else if(type == 2 && stage == 2)
                        atk = 113;
                    else if(type == 3 && stage == 0)
                        atk = 65;
                    else if(type == 3 && stage == 1)
                        atk = 97;
                    else
                        atk = 124;
                    myfile << hex <<pow(2,stage)<<pow(2,type)<<" "<<setw(2)<< setfill('0')<<hp<<" "<<atk<<" "<<setw(2)<< setfill('0')<<exp<<endl;
                }
                else // type = 4, normal = 5
                {
                    stage = 1; // Lowest
                    hp = rand() % 125;
                    atk = 62;
                    exp = rand() % 29;

                    myfile << hex <<stage<<(type+1)<<" "<<setw(2)<< setfill('0')<<hp<<" "<<atk<<" "<<setw(2)<< setfill('0')<<exp<<endl;
                }

            }
        }
    }
    myfile.close();

  /*
    int min = 10;
    int max = 15;

    int x = rand() % (max - min + 1) + min;


    cout << hex << "x = " << x << endl;

*/

    return 0;
}
