#pragma once

#include <cctype>
#include <string>
#include <vector>

inline std::string trimText(const std::string &value)
{
    int left = 0;
    int right = static_cast<int>(value.size()) - 1;

    while (left <= right && std::isspace(static_cast<unsigned char>(value[left]))) {
        ++left;
    }
    while (right >= left && std::isspace(static_cast<unsigned char>(value[right]))) {
        --right;
    }

    if (left > right) {
        return "";
    }
    return value.substr(left, right - left + 1);
}

inline std::vector<std::string> splitText(const std::string &line, char delimiter)
{
    std::vector<std::string> parts;
    std::string current;

    for (char ch : line) {
        if (ch == delimiter) {
            parts.push_back(trimText(current));
            current.clear();
        } else {
            current.push_back(ch);
        }
    }
    parts.push_back(trimText(current));
    return parts;
}

inline bool startsWithCommentOrEmpty(const std::string &line)
{
    const std::string trimmed = trimText(line);
    return trimmed.empty() || trimmed[0] == '#';
}

