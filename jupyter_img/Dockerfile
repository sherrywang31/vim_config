FROM python:3.8-slim
MAINTAINER Sherry Wang <@cars.com>

WORKDIR /app

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends git build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Update pip and install latest patch for the specified minor version of useful
# python packages
RUN python -m pip install --no-cache-dir -U pip && python -m pip install --no-cache-dir \
    jupyter \
    'boto3~=1.14.0' \
    'matplotlib' \
    'numpy' \
    'pandas' \
    'psycopg2-binary~=2.8.0' \
    'pyarrow' \
    's3fs' \
    'scikit-learn' \
    'scipy' \
    'seaborn' \
    'sqlalchemy-redshift~=0.7.9' \
    sentence-transformers \
    gensim \
    numba \
    pandas_profiling \
    pyyaml \
    xgboost \
    category_encoders

# Allow user to override IP on docker run
ENV IP 0.0.0.0

# Copy the custom config
COPY jupyter_custom.js /root/.jupyter/custom/custom.js

ENTRYPOINT exec jupyter notebook --no-browser --allow-root --ip=${IP}
