#pragma once

#include <cmath>
#include <vector>

#include "Waypoint.h"

struct RoadWithPoints {
    int from = -1;
    int to = -1;
    int weight = 0;
    std::vector<Waypoint> points;

    double calcDistance(double scale) const
    {
        if (points.size() < 2) {
            return 0.0;
        }

        double pixels = 0.0;
        for (size_t i = 1; i < points.size(); ++i) {
            const double dx = points[i].x - points[i - 1].x;
            const double dy = points[i].y - points[i - 1].y;
            pixels += std::sqrt(dx * dx + dy * dy);
        }
        return pixels * scale;
    }
};

