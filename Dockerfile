# Stage 1: Build stage for installing dependencies
FROM python:3.12-slim AS builder

# Set the working directory
WORKDIR /app

# Copy the requirements file into the image
COPY requirements.txt requirements.txt

# Install the Python dependencies into a temporary location
RUN pip install --no-cache-dir --target /install -r requirements.txt

# Stage 2: Final image with InterSystems IRIS and the installed Python libraries
FROM containers.intersystems.com/intersystems/iris-community:2026.1

# Switch to the root user to install necessary system packages
USER root

# Install Python support and the JVM required by the IRIS LOAD DATA command.
RUN apt-get update && apt-get install -y libpython3.12-dev default-jre-headless && \
    rm -rf /var/lib/apt/lists/*

# Set the environment variables for Embedded Python
ENV PythonRuntimeLibrary=/usr/lib/x86_64-linux-gnu/libpython3.12.so
ENV PythonRuntimeLibraryVersion=3.12

# Update the LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}

# Remove any preinstalled IRIS SQLAlchemy dialect before copying the official
# sqlalchemy-intersystems-iris distribution installed from requirements.txt.
# Stale package metadata can make SQLAlchemy discover the wrong dialect.
RUN rm -rf /usr/irissys/mgr/python/sqlalchemy_iris \
    /usr/irissys/mgr/python/sqlalchemy_iris-*.dist-info \
    /usr/irissys/mgr/python/sqlalchemy_intersystems_iris-*.dist-info

# Copy the installed Python packages from the builder stage
COPY --from=builder /install /usr/irissys/mgr/python

# Your own Python package
COPY python_utils /usr/irissys/mgr/python/python_utils
ENV PYTHONPATH=/usr/irissys/mgr/python:${PYTHONPATH}


# Keep the application source available without compiling it during data setup.
COPY MockPackage /usr/irissys/mgr/MockPackage
# Copy the generic SQL bootstrap location and the repository data sources.
# The Docker Compose /dur bind mount overrides /dur with the working copy.
COPY sql /usr/irissys/mgr/sql
COPY dur/data /dur/data
ENV IRIS_SQL_FILE=/usr/irissys/mgr/sql/bootstrap.sql
# Copy and set permissions for the autoconf script while still root
COPY iris_autoconf.sh /usr/irissys/iris_autoconf.sh
RUN sed -i 's/\r$//' /usr/irissys/iris_autoconf.sh && \
    find /usr/irissys/mgr/sql -type f -name '*.sql' -exec sed -i 's/\r$//' {} + && \
    chmod +x /usr/irissys/iris_autoconf.sh && \
    chown -R irisowner:irisowner /dur/data /usr/irissys/mgr/sql

# Switch back to the default `irisowner` user
USER irisowner
