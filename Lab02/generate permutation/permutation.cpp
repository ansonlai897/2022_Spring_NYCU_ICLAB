#include <iostream>

using namespace std;
const int N = 5;
int a[N] = {0, 1, 2, 3, 4};
int c[N];   // factorial number system
int cnt=0;
void print()
{
    cout << "{";
    for (int i=0; i<N; ++i) cout  << a[i] << ", " ;
    cout << "}";
    cout << '\n';
}

void enumerate_permutations()
{
    for (int i=0; i<N; ++i) c[i] = 0;

    print();
    for (int i=0; i<N; )
        if (c[i] < i)
        {
            swap(a[i & 1 ? c[i] : 0], a[i]);
            c[i]++;
            i = 0;
            print();
            cnt ++;
        }
        else
            c[i++] = 0;
}
int main()
{
    enumerate_permutations();
    cout << cnt;
    return 0;
}
