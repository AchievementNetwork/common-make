TESTS=$(wildcard test/test[0-9]*)

# Simple set of tests
test:
	$(foreach TEST,$(TESTS),(cd $(TEST) && sh ../test.sh || kill $$$$) ;)

.PHONY: test
