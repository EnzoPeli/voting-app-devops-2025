#!/bin/bash


# Aplica todos los YAMLs con sustitución de variables
for file in ./k8s/**/**/*.yaml ./k8s/**/*.yaml ./k8s/*.yaml; do
  echo "📄 Aplicando $file"
  envsubst < "$file" | kubectl apply -n $NAMESPACE -f -
done
