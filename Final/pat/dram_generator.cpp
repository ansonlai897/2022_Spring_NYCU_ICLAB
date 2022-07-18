#include <fstream>
#include <cmath>
#include <vector>
#include <iostream>
#include <sstream>
#include <string>
 
using namespace std;
 
const double temporal_0[5] = {0.3, 0, 0.3, 0, 0.3};

string d_h_convert(int decimal_value){
    std::stringstream ss;
    ss<< std::hex << decimal_value; // int decimal_value
    std::string res ( ss.str() );
    //std::cout << res <<endl;
    return res;
}
void print_stop_probability(vector<double>& stop_probability){
    for(int j=1; j < stop_probability.size(); j++){
        if( j == 251 ) cout<<"bin251~255 : ";
        else if( j%10 == 1 ) cout<<"bin"<<j<<"~"<<j+9<<" : ";
        cout << stop_probability[j]<<" ";
        if( j%10 == 0 || j == 255) cout<<endl;
    }   
}
void print_bins_value(vector<int>& bins_value){
    if(bins_value.empty())
        cout<<"bins is empty!"<<endl;
    for(int j=1; j < bins_value.size(); j++){
        if( j == 251 ) cout<<"bin251~256 : ";
        else if( j%10 == 1 ) cout<<"bin"<<j<<"~"<<j+9<<" : ";
        cout << bins_value[j]<<" ";
        if( j%10 == 0 || j == 256) cout<<endl;
    }   
}
void print_bins_probability(vector<int>& bins_value){
    int count_stop = 0;
    double portion;
    for(int j=1; j <= 255; j++){
        count_stop += bins_value[j];
    }   
    portion = count_stop / (15.0*255.0);
    cout<<"portion:"<<portion<<endl;
}

void generate_one_pixel (vector<int> & bins_value, ofstream & golden_distance ){ //generate one pixel(one histogram)

        //generate 255 bins probability 
        int distance = rand() % 250 + 1 ;//generate type0 distance: 1~251
        //cout<<"distance:"<<distance<<endl;
        vector<double> stop_probability; //stop porbability: vector size = 255 (1~255)
        stop_probability.push_back(0.0); //bin0, no use
        for(int j=1; j<=255 ; j++){ //bin 1~255, background noise = 0.3
            stop_probability.push_back(0.3);
        }
        for(int j = distance; j <= (distance + 4) ; j++ ){ //add temporal correlation 
            stop_probability[j] += temporal_0[j - distance];
        }
        //print_stop_probability(stop_probability); 
        // here done the 1~255 bins probability

        //generate 255 bins value 
        bins_value.clear();
        bins_value.push_back(0); //bin0 no use
        for(int j=1;j<=255;j++){ //bin1~bin255
            int count_stop = 0;
            double portion = 0.0;
            for(int k=0;k<15;k++){ //each bin has 15 starts in type0
                double probability = stop_probability[j]; //probability of (stop=1)
                int threshold = probability * 10;
                bool stop ;
                if(rand()%10 < threshold){
                    stop = 1;
                    count_stop++;
                }
            }
            bins_value.push_back(count_stop);
        }
        //end generate 255 bin values
        golden_distance<< distance <<endl;
        bins_value.push_back(0); //bin 256: distance -> initialize as 0
        ///print_bins_value(bins_value);
        //print_bins_probability(bins_value);
}

int main(){
    srand(888);
    cout<<"program start "<<endl;

    ofstream output;
    output.open("dram.dat", ios::out);
    output << endl;

    ofstream golden_distance;
    golden_distance.open("golden_distance.txt", ios::out);

    int frame_id = 0; //0~31 (hex:10~2f)
    int pixel_id = 0; //0~15 (hex: 0~f)
    int dram_index = 65536; //10000 ~ 2fffc

    for(int f_id=0 ; f_id<=31; f_id++){ //has 32 frames
        for(int p_id=0 ; p_id<16 ; p_id++){ //each frame has 16 pixels
            vector<int> bins_value;
            generate_one_pixel(bins_value , golden_distance); //generate one histogram (256 bins)
            
            //these two lines print information in decimal format
            //cout<<d_h_convert(dram_index) <<endl;
            //print_bins_value(bins_value);

            for(int b_id=1 ; b_id <= 256 ; b_id ++ ){ //each pixels has 256 bins
                if(b_id % 4 == 1){ //1,5,9.....   print the @10000 ~ @2fffc part
                    output << "@" << d_h_convert(dram_index) <<endl;
                    dram_index += 4;
                }
                if( bins_value[b_id] < 16 ) //print bin value part
                    output <<"0"<< d_h_convert( bins_value[b_id] )<<" ";
                else
                    output <<d_h_convert( bins_value[b_id] )<<" ";
                
                if(b_id % 4 == 0)
                    output << endl;
            }
        }
    }
    cout<<"program end "<<endl;
}
