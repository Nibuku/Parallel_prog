cmake_minimum_required(VERSION 3.10)
project(MatrixMultiplicationMPI LANGUAGES CXX)

# Настройка стандарта C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Поиск MPI (для Linux через WSL)
find_package(MPI REQUIRED)

# Создание исполняемого файла
add_executable(generate_write
        generate_write.cpp  # Замените на ваш исходный файл
)

# Подключение MPI
target_link_libraries(generate_write
        PRIVATE
        MPI::MPI_CXX
)

# Дополнительные флаги компиляции
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(generate_write PRIVATE -Wall -Wextra)
endif()