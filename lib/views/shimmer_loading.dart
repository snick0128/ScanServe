import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading {
  static Widget menuItemCard({bool isMobile = false, bool isTablet = false}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withAlpha(25),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: isMobile ? 120 : 140,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shimmer
                Container(
                  height: isMobile ? 18 : 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                // Description shimmer
                Container(
                  height: isMobile ? 14 : 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: isMobile ? 4 : 6),
                Container(
                  height: isMobile ? 14 : 16,
                  width: isMobile ? 150 : 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 12),
                // Price and button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price shimmer
                    Container(
                      height: isMobile ? 16 : 18,
                      width: isMobile ? 60 : 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Button shimmer
                    Container(
                      height: isMobile ? 32 : 36,
                      width: isMobile ? 70 : 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget cartItem({bool isMobile = false, bool isTablet = false}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withAlpha(25),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Row(
          children: [
            // Item details shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: isMobile ? 16 : 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Container(
                    height: isMobile ? 14 : 16,
                    width: isMobile ? 80 : 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            // Quantity controls shimmer
            Container(
              height: isMobile ? 32 : 36,
              width: isMobile ? 100 : 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            // Total shimmer
            Container(
              height: isMobile ? 16 : 18,
              width: isMobile ? 60 : 70,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget orderCard({bool isMobile = false, bool isTablet = false}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withAlpha(25),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header shimmer
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 12,
            ),
            title: Container(
              height: isMobile ? 14 : 16,
              width: isMobile ? 120 : 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            subtitle: Container(
              height: isMobile ? 12 : 14,
              width: isMobile ? 100 : 120,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            trailing: Container(
              height: isMobile ? 16 : 18,
              width: isMobile ? 60 : 70,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Expanded content shimmer (when expanded)
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items list shimmer
                ...List.generate(2, (index) => Padding(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 2 : 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: isMobile ? 14 : 16,
                        width: isMobile ? 120 : 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: isMobile ? 14 : 16,
                        width: isMobile ? 50 : 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                )),
                SizedBox(height: isMobile ? 8 : 12),
                // Summary shimmer
                ...List.generate(3, (index) => Padding(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 2 : 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: isMobile ? 12 : 14,
                        width: isMobile ? 60 : 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: isMobile ? 12 : 14,
                        width: isMobile ? 50 : 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildShimmerList({
    required int itemCount,
    required Widget Function(int) itemBuilder,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: itemBuilder(index),
        );
      },
    );
  }

  static Widget buildShimmerGrid({
    required int itemCount,
    required int crossAxisCount,
    required Widget Function(int) itemBuilder,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1,
        crossAxisSpacing: isMobile ? 8 : 16,
        mainAxisSpacing: isMobile ? 8 : 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: itemBuilder(index),
        );
      },
    );
  }
}
