#include "math-utils/vector.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

using namespace math_utils;

void test_vector_construction() {
    std::cout << "Testing vector construction...\n";
    
    Vector3 v1;
    assert(v1.x() == 0.0 && v1.y() == 0.0 && v1.z() == 0.0);
    
    Vector3 v2(1.0, 2.0, 3.0);
    assert(v2.x() == 1.0 && v2.y() == 2.0 && v2.z() == 3.0);
    
    std::cout << "✓ Vector construction tests passed\n";
}

void test_vector_operations() {
    std::cout << "Testing vector operations...\n";
    
    Vector3 v1(1.0, 2.0, 3.0);
    Vector3 v2(4.0, 5.0, 6.0);
    
    // Addition
    Vector3 sum = v1 + v2;
    assert(sum.x() == 5.0 && sum.y() == 7.0 && sum.z() == 9.0);
    
    // Subtraction
    Vector3 diff = v2 - v1;
    assert(diff.x() == 3.0 && diff.y() == 3.0 && diff.z() == 3.0);
    
    // Scalar multiplication
    Vector3 scaled = v1 * 2.0;
    assert(scaled.x() == 2.0 && scaled.y() == 4.0 && scaled.z() == 6.0);
    
    // Dot product
    double dot = v1.dot(v2);
    assert(std::abs(dot - 32.0) < 1e-10);  // 1*4 + 2*5 + 3*6 = 32
    
    // Cross product
    Vector3 cross = v1.cross(v2);
    assert(std::abs(cross.x() - (-3.0)) < 1e-10);  // 2*6 - 3*5 = -3
    assert(std::abs(cross.y() - 6.0) < 1e-10);     // 3*4 - 1*6 = 6
    assert(std::abs(cross.z() - (-3.0)) < 1e-10);  // 1*5 - 2*4 = -3
    
    std::cout << "✓ Vector operations tests passed\n";
}

void test_vector_magnitude() {
    std::cout << "Testing vector magnitude...\n";
    
    Vector3 v(3.0, 4.0, 0.0);
    double mag = v.magnitude();
    assert(std::abs(mag - 5.0) < 1e-10);  // sqrt(3^2 + 4^2) = 5
    
    Vector3 unit = v.normalized();
    assert(std::abs(unit.magnitude() - 1.0) < 1e-10);
    
    std::cout << "✓ Vector magnitude tests passed\n";
}

int main() {
    std::cout << "Running Vector Tests\n";
    std::cout << "===================\n";
    
    test_vector_construction();
    test_vector_operations();
    test_vector_magnitude();
    
    std::cout << "\n✓ All vector tests passed!\n";
    return 0;
}
