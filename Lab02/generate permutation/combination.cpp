#include<iostream>
#include<vector>
using namespace std;

void comb(int n, int m);


int main() {
    int m=8, n=5;
    comb(n, m);
    system("pause");
    return 0;
}

void comb(int n, int m) {
    vector < int > list;
    for (int i = 0; i < n; ++i) {
        list.push_back(i);
    }
    --list[n - 1];
    do {
        for (int i = n - 1; i >= 0; --i) {
            if (list[i] < m + i - n) {
                ++list[i];
                for (int j = i + 1; j < n; ++j) {
                    list[j] = list[i] + j - i;
                }
                break;
            }
        }
        for (int i = 0; i < n; ++i) {
            cout << list[i] << ", ";
        }
        cout << endl;
    } while (list[0] < (m - n));
}
