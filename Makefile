CXX = g++
CXXFLAGS = -std=c++23 -O2 -msse4.1 -mpclmul
INCLUDES = -I. -I./src -I/usr/include/botan-2
LIBS = -lssl -lcrypto -lbotan-2

# Output binary
TARGET = building/KryptoCpp

# Source files
SRCS = src/algorithms/ddf.cpp \
       src/algorithms/edf.cpp \
       src/algorithms/gcm.cpp \
       src/algorithms/padding_oracle.cpp \
       src/algorithms/sea128.cpp \
       src/algorithms/sff.cpp \
       src/algorithms/xex_fde.cpp \
       src/main.cpp \
       src/math/galois.cpp \
       src/math/polynom.cpp \
       src/util/base64_utils.cpp \
       src/util/processor.cpp

# Object files
OBJS = $(SRCS:%.cpp=building/%.o)

# Make sure build directories exist
BUILD_DIRS = building/src/algorithms building/src/math building/src/util

# Default target
all: $(BUILD_DIRS) $(TARGET)

# Create build directories
$(BUILD_DIRS):
	mkdir -p $@

# Link the final executable
$(TARGET): $(OBJS)
	$(CXX) $(OBJS) -o $(TARGET) $(LIBS)

# Compile source files
building/%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Clean build files
clean:
	rm -rf building

# Phony targets
.PHONY: all clean

# Generate dependencies automatically
DEPS = $(OBJS:.o=.d)
-include $(DEPS)