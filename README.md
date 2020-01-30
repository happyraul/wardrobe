# Wardrobe

## Local development

Compile & run shell:

    iex -S mix

Test some endpoints:

* all: `curl -v '127.0.0.1:5456/all?user=vidak'`
* add_item: `curl -X 'POST' -v '127.0.0.1:5456/add_item?user=vidak&name=scarf&color=red'`
* update_item: `curl -X 'POST' -v '127.0.0.1:5456/update_item?user=raul&item_id=1&name=shirt'`
* delete_item: `curl -X 'DELETE' -v '127.0.0.1:5456/delete_item?user=raul&id=1'`
