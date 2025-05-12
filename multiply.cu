#include <iostream>
#include <fstream>
#include <vector>
#include <random>
#include <chrono>
#include <string>
#include <sstream>
#include <iomanip>
#include "cuda_runtime.h"

using namespace std;

// Error checking macro for CUDA calls
#define CHECK_CUDA_ERROR(call) \
{ \
    cudaError_t err = call; \
    if (err != cudaSuccess) { \
        cerr << "CUDA error in " << #call << ": " << cudaGetErrorString(err) << " at " << __FILE__ << ":" << __LINE__ << endl; \
        exit(EXIT_FAILURE); \
    } \
}

// Kernel for matrix multiplication
__global__ void matrixMultiplyKernel(const int* A, const int* B, int* C, int n) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < n && col < n) {
        int sum = 0;
        for (int k = 0; k < n; k++) {
            sum += A[row * n + k] * B[k * n + col];
        }
        C[row * n + col] = sum;
    }
}

int get_random_number(int min, int max) {
    static random_device rd;
    static mt19937 gen(rd());
    uniform_int_distribution<int> dist(min, max);
    return dist(gen);
}

vector<vector<int>> generate_matrix(int size, int minVal = 1, int maxVal = 100) {
    vector<vector<int>> matrix(size, vector<int>(size));
    for (auto& row : matrix) {
        for (auto& elem : row) {
            elem = get_random_number(minVal, maxVal);
        }
    }
    return matrix;
}

void save_matrix(const vector<vector<int>>& matrix, const string& filename) {
    ofstream out(filename);
    for (const auto& row : matrix) {
        for (size_t i = 0; i < row.size(); ++i) {
            out << row[i];
            if (i != row.size() - 1) out << " ";
        }
        out << "\n";
    }
}

vector<vector<int>> read_matrix(const string& filename) {
    ifstream in(filename);
    vector<vector<int>> matrix;
    string line;

    while (getline(in, line)) {
        vector<int> row;
        istringstream iss(line);
        int num;
        while (iss >> num) {
            row.push_back(num);
        }
        matrix.push_back(row);
    }

    return matrix;
}

vector<vector<int>> multiply_matrices_cuda(const vector<vector<int>>& A, const vector<vector<int>>& B) {
    int n = A.size();

    // Flatten matrices
    vector<int> A_flat(n * n);
    vector<int> B_flat(n * n);
    vector<int> C_flat(n * n);

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            A_flat[i * n + j] = A[i][j];
            B_flat[i * n + j] = B[i][j];
        }
    }

    // Allocate device memory
    int *d_A, *d_B, *d_C;
    CHECK_CUDA_ERROR(cudaMalloc(&d_A, n * n * sizeof(int)));
    CHECK_CUDA_ERROR(cudaMalloc(&d_B, n * n * sizeof(int)));
    CHECK_CUDA_ERROR(cudaMalloc(&d_C, n * n * sizeof(int)));

    // Copy data to device
    CHECK_CUDA_ERROR(cudaMemcpy(d_A, A_flat.data(), n * n * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA_ERROR(cudaMemcpy(d_B, B_flat.data(), n * n * sizeof(int), cudaMemcpyHostToDevice));

    // Define block and grid dimensions
    dim3 threadsPerBlock(16, 16);
    dim3 blocksPerGrid((n + threadsPerBlock.x - 1) / threadsPerBlock.x,
                       (n + threadsPerBlock.y - 1) / threadsPerBlock.y);

    // Launch kernel
    matrixMultiplyKernel<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, n);
    CHECK_CUDA_ERROR(cudaGetLastError());

    // Copy result back to host
    CHECK_CUDA_ERROR(cudaMemcpy(C_flat.data(), d_C, n * n * sizeof(int), cudaMemcpyDeviceToHost));

    // Free device memory
    CHECK_CUDA_ERROR(cudaFree(d_A));
    CHECK_CUDA_ERROR(cudaFree(d_B));
    CHECK_CUDA_ERROR(cudaFree(d_C));

    // Convert flat result back to 2D vector
    vector<vector<int>> result(n, vector<int>(n));
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            result[i][j] = C_flat[i * n + j];
        }
    }

    return result;
}

int main() {
    // Check for CUDA device
    int deviceCount;
    CHECK_CUDA_ERROR(cudaGetDeviceCount(&deviceCount));
    if (deviceCount == 0) {
        cerr << "No CUDA devices found" << endl;
        return EXIT_FAILURE;
    }
    cout << "Found " << deviceCount << " CUDA device(s)" << endl;

    const string results_dir = "C:/Users/Yana/Documents/parallel_prog/pp_labs/lab_1/results";
    ofstream stats("statistics_cuda.txt");

    for (int size = 100; size <= 3100; size += 200) {
        cout << "Size: " << size << "x" << size << endl;

        auto matrix1 = generate_matrix(size);
        auto matrix2 = generate_matrix(size);

        string file1 = results_dir + "/" + to_string(size) + "_1.txt";
        string file2 = results_dir + "/" + to_string(size) + "_2.txt";
        save_matrix(matrix1, file1);
        save_matrix(matrix2, file2);

        auto start = chrono::high_resolution_clock::now();
        auto result = multiply_matrices_cuda(matrix1, matrix2);
        auto end = chrono::high_resolution_clock::now();

        string result_file = results_dir + "/result_cuda_" + to_string(size) + ".txt";
        save_matrix(result, result_file);

        auto duration = chrono::duration_cast<chrono::milliseconds>(end - start);
        stats << size << "\t" << duration.count() << " ms\n";

        cout << "  CUDA time: " << duration.count() << " ms\n";

        // Optional: Verify against CPU implementation
        /*
        auto cpu_start = chrono::high_resolution_clock::now();
        auto cpu_result = multiply_matrices(matrix1, matrix2);
        auto cpu_end = chrono::high_resolution_clock::now();
        auto cpu_duration = chrono::duration_cast<chrono::milliseconds>(cpu_end - cpu_start);
        cout << "  CPU time: " << cpu_duration.count() << " ms\n";
        */
    }
    stats.close();
    cout << "Check statistics_cuda.txt for results\n";
    return 0;
}