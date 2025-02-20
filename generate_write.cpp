#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <random>
#include <ctime>

using namespace std;

auto engine = std::mt19937(std::time(nullptr));

vector<vector<int>> generate(size_t size) {
	vector<vector<int>> matrix(size, vector<int>(size)); 
	for (auto& i : matrix) {
		for (int& j : i) {
			j = engine() % RAND_MAX;
		}
	}
	return matrix;
}

void write_to_file(const vector<vector<int>>& matrix, const string& path) {
	std::ofstream out;
	out.open(path);
	for ( const auto& i : matrix) {
		for (int j : i) 
			out << j << " ";
		out << std::endl;
	}
	out.close();
}

/*vector<vector<int>> read_from_file(const string& path) {
	vector<vector<int>> matrix;
	std::ifstream in(path); // окрываем файл для чтения
	if (in.is_open())
	{
		double x, y;
		while (in >> x >> y)
		{
			new_points.push_back(Point{ x, y });
		}
	}
	in.close();
}*/



vector<vector<int>> mul_matrix(const vector<vector<int>>& matrix1, const vector<vector<int>>& matrix2) {
	size_t size = matrix1.size();
	vector<vector<int>> result(size, vector<int>(size, 0));
	for (int i = 0; i < size; ++i) {
		for (int j = 0; j < size; ++j) {
			for (int k = 0; k < size; ++k) {
				result[i][j] += matrix1[i][k] * matrix2[k][j];
			}
		}
	}
	return result;
}

int main() {
	vector<vector<int>> matrix1 = generate(3);
	vector<vector<int>> matrix2 = generate(3);
	write_to_file(matrix1, "matrix1.txt");
	write_to_file(matrix2, "matrix2.txt");
	vector<vector<int>> result = mul_matrix(matrix1, matrix2);
	write_to_file(result, "result.txt");
}