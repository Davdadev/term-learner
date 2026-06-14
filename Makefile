.PHONY: generate open clean

# Install xcodegen if needed, then generate the Xcode project
generate:
	@which xcodegen > /dev/null 2>&1 || brew install xcodegen
	xcodegen generate

# Generate and open in Xcode
open: generate
	open TermLearner.xcodeproj

# Remove generated Xcode project (re-generate any time with `make generate`)
clean:
	rm -rf TermLearner.xcodeproj
