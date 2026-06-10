#pragma once

#include <string>

struct Spot {
    int id = -1;
    std::string name;
    std::string type;
    std::string intro;
    double x = 0.0;
    double y = 0.0;
};

