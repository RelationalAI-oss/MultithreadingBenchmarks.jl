#include <iostream>
#include <thread>
#include <queue>
using namespace std;

const int NTHREADS = 3;
std::thread t[NTHREADS];


// Create work-queue
using request_t = int;
std::mutex m;
std::condition_variable cv;
std::queue<request_t> requests;
bool processed = false;
int sum = 0;

void worker_thread() {
    // Wait until we have work ready
    std::unique_lock<std::mutex> lk(m);
    cv.wait(lk, []{return !requests.empty();});

    // after the wait, we own the lock.
    std::cout << "Worker thread is processing data\n";
    sum += requests.front();
    requests.pop();

    // Send data back to main()
    processed = true;
    std::cout << "Worker thread signals sum processing completed\n";

    // Manual unlocking is done before notifying, to avoid waking up
    // the waiting thread only to block again (see notify_one for details)
    lk.unlock();
    cv.notify_one();
}


int main() {
   std::thread worker(worker_thread);

   // send data to the worker thread
   {
       std::lock_guard<std::mutex> lk(m);
       requests.push(1);
       std::cout << "main() signals data ready for processing\n";
   }
   cv.notify_one();

   // wait for the worker
   {
       std::unique_lock<std::mutex> lk(m);
       cv.wait(lk, []{return processed;});
   }
   std::cout << "Back in main(), sum = " << sum << '\n';

   worker.join();
}
