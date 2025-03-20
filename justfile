doc-preview:
    swift package --disable-sandbox preview-documentation --source-service github --source-service-base-url "https://github.com/itsactuallyluna9/Quay/blob/main" --checkout-path $(pwd)

gen-proto:
    protoc --swift_out=. Sources/Quay/**/*.proto
