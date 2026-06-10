#pragma once

#include <vector>

struct HeapNode {
    int vertex = -1;
    int distance = 0;
};

class MinHeap {
public:
    bool isEmpty() const { return nodes.empty(); }

    void push(const HeapNode &node)
    {
        nodes.push_back(node);
        heapifyUp(static_cast<int>(nodes.size()) - 1);
    }

    HeapNode pop()
    {
        HeapNode result = nodes[0];
        nodes[0] = nodes.back();
        nodes.pop_back();
        if (!nodes.empty()) {
            heapifyDown(0);
        }
        return result;
    }

private:
    std::vector<HeapNode> nodes;

    void swapNodes(int a, int b)
    {
        HeapNode temp = nodes[a];
        nodes[a] = nodes[b];
        nodes[b] = temp;
    }

    void heapifyUp(int index)
    {
        while (index > 0) {
            const int parent = (index - 1) / 2;
            if (nodes[parent].distance <= nodes[index].distance) {
                break;
            }
            swapNodes(parent, index);
            index = parent;
        }
    }

    void heapifyDown(int index)
    {
        while (true) {
            const int left = index * 2 + 1;
            const int right = index * 2 + 2;
            int smallest = index;

            if (left < static_cast<int>(nodes.size()) && nodes[left].distance < nodes[smallest].distance) {
                smallest = left;
            }
            if (right < static_cast<int>(nodes.size()) && nodes[right].distance < nodes[smallest].distance) {
                smallest = right;
            }
            if (smallest == index) {
                break;
            }
            swapNodes(index, smallest);
            index = smallest;
        }
    }
};

