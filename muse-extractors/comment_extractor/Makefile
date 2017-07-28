all: CommentExtractor

%.cpp: %.ll
	flex++ -o $@ $< 

CommentExtractor: CommentExtractor.cpp CommentScanner.cpp
	g++ -O3 CommentExtractor.cpp CommentScanner.cpp -o CommentExtractor
