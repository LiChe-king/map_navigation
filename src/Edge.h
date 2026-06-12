#pragma once

struct Edge {
    int to = -1;
    int weight = 0;
    
    Edge() = default;
    Edge(int t, int w) : to(t), weight(w) {}
};