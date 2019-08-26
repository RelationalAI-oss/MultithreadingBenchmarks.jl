#include <iostream>
#include <thread>
#include <queue>
#include <cstring>
#include "julia.h"
using namespace std;

// using jl_task_t = void;
extern "C" {
  // Julia Internals Includes
  int jl_enqueue_task(jl_task_t *task);
}


const int NTHREADS = 3;
std::thread thread_pool[NTHREADS];

extern "C" {
  struct Request {
    int input;
    void* response_ptr;
    size_t response_size;
    jl_task_t *task;
  };

  void enqueue(int input, void* response_ptr, size_t response_size, jl_task_t *task);
}

// Create work-queue
using request_t = int;
std::mutex m;
std::condition_variable cv;
std::queue<Request> requests;

// The worker thread infinite-loops, waiting for work to arrive in the requests queue,
// which it handles and then schedules the provided julia task callback when it's finished.
void worker_thread() {
  std::cout << "Worker thread running!\n";
    while (true) {
      // Wait until we have work ready
      std::unique_lock<std::mutex> lk(m);
      cv.wait(lk, []{return !requests.empty();});

      // after the wait, we own the lock.
      std::cout << "Worker thread is processing request\n";
      auto r = requests.front();
      requests.pop();

      // Process data
      auto out = r.input + 1;
      //memcpy(r.response_ptr, &out, r.response_size);
      *((int*)r.response_ptr) = out;
      std::cout << "Wrote response: " << out << endl;

      // Send data back to caller
      std::cout << "Worker thread signals sum processing completed\n";
      int status = jl_enqueue_task(r.task);
      std::cout << "Enqueue status: " << status << std::endl;

      // This unlocks when the scope ends
    }
}

extern "C" {
  // Spawn NTHREADS threads in our thread pool, and have them all wait for enqueued work in a loop
  void init_thread_pool() {
    for (int i = 0; i < NTHREADS; ++i) {
      thread_pool[i] = std::thread(worker_thread);
      // return and allow the worker to continue running asynchronously.
      thread_pool[i].detach();
    }
  }

  // Enqueue a new request, and notify a thread to wake up and handle it.
  void enqueue(int input, void* response_ptr, size_t response_size, jl_task_t *task) {
    std::cout << "enqueue(): " << input <<" "<< response_ptr <<" "<< response_size <<" "<< task << endl;

    // send data to the worker threads
    {
      std::lock_guard<std::mutex> lk(m);
      requests.push(Request{input, response_ptr, response_size, task});
      std::cout << "enqueue() signals data ready for processing\n";
    }
    cv.notify_one();
  }
}
