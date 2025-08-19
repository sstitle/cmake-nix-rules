#include "math-utils/matrix.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

using namespace math_utils;

void test_matrix_construction() {
    std::cout << "Testing matrix construction...\n";
    
    Matrix3x3 m1;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            assert(m1(i, j) == 0.0);
        }
    }
    
    Matrix3x3 identity = Matrix3x3::identity();
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            if (i == j) {
                assert(identity(i, j) == 1.0);
            } else {
                assert(identity(i, j) == 0.0);
            }
        }
    }
    
    std::cout << "✓ Matrix construction tests passed\n";
}

void test_matrix_operations() {
    std::cout << "Testing matrix operations...\n";
    
    Matrix3x3 m1({{{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}});
    Matrix3x3 m2({{{2, 0, 0}, {0, 2, 0}, {0, 0, 2}}});
    
    // Addition
    Matrix3x3 sum = m1 + m2;
    assert(sum(0, 0) == 3.0 && sum(1, 1) == 7.0 && sum(2, 2) == 11.0);
    
    // Scalar multiplication
    Matrix3x3 scaled = m1 * 2.0;
    assert(scaled(0, 0) == 2.0 && scaled(1, 1) == 10.0 && scaled(2, 2) == 18.0);
    
    // Matrix-vector multiplication
    Vector3 v(1.0, 1.0, 1.0);
    Vector3 result = m1 * v;
    assert(result.x() == 6.0);   // 1*1 + 2*1 + 3*1 = 6
    assert(result.y() == 15.0);  // 4*1 + 5*1 + 6*1 = 15
    assert(result.z() == 24.0);  // 7*1 + 8*1 + 9*1 = 24
    
    std::cout << "✓ Matrix operations tests passed\n";
}

void test_matrix_determinant_and_inverse() {
    std::cout << "Testing matrix determinant and inverse...\n";
    
    // Test determinant
    Matrix3x3 m({{{2, 0, 0}, {0, 2, 0}, {0, 0, 2}}});
    double det = m.determinant();
    assert(std::abs(det - 8.0) < 1e-10);  // det of 2*I = 2^3 = 8
    
    // Test inverse
    Matrix3x3 inv = m.inverse();
    Matrix3x3 identity = m * inv;
    
    // Check if m * inv = identity (within tolerance)
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            double expected = (i == j) ? 1.0 : 0.0;
            assert(std::abs(identity(i, j) - expected) < 1e-10);
        }
    }
    
    std::cout << "✓ Matrix determinant and inverse tests passed\n";
}

void test_matrix_transpose() {
    std::cout << "Testing matrix transpose...\n";
    
    Matrix3x3 m({{{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}});
    Matrix3x3 t = m.transpose();
    
    assert(t(0, 0) == 1.0 && t(0, 1) == 4.0 && t(0, 2) == 7.0);
    assert(t(1, 0) == 2.0 && t(1, 1) == 5.0 && t(1, 2) == 8.0);
    assert(t(2, 0) == 3.0 && t(2, 1) == 6.0 && t(2, 2) == 9.0);
    
    std::cout << "✓ Matrix transpose tests passed\n";
}

int main() {
    std::cout << "Running Matrix Tests\n";
    std::cout << "===================\n";
    
    test_matrix_construction();
    test_matrix_operations();
    test_matrix_determinant_and_inverse();
    test_matrix_transpose();
    
    std::cout << "\n✓ All matrix tests passed!\n";
    return 0;
}
