#pragma once

struct Node {
    int id = -1;
    double x = 0.0;
    double y = 0.0;
    
    Node() = default;
    Node(int i, double px, double py) : id(i), x(px), y(py) {}
};