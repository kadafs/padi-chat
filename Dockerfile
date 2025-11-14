ARG RUBY_VERSION=3.3.5
FROM ruby:${RUBY_VERSION}-slim-bullseye

ARG APP_ENV=production

ARG PG_MAJOR=15
ARG NODE_MAJOR=16
ARG BUNDLER_VERSION=2.3.26
ARG YARN_VERSION=1.13.0

# Copy Installers
RUN mkdir -p /docker-files
COPY .docker-files/ /docker-files
RUN chmod +x /docker-files/*.sh

# Install Dependencies
RUN /docker-files/deps.sh

# Install PostgreSQL
RUN /docker-files/pg.sh

# Install NodeJS, Yarn
RUN /docker-files/node.sh

# Configure bundler
ENV LANG=C.UTF-8 BUNDLE_JOBS=4 BUNDLE_RETRY=3

# Uncomment this line if you want to run binstubs without prefixing with `bin/` or `bundle exec`
# ENV PATH=/app/bin:$BUNDLE_BIN:$PATH

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:$BUNDLER_VERSION

# Change permissions for GEM_HOME
RUN chmod -R 777 $GEM_HOME

# Add docker user
RUN adduser --disabled-password --gecos "" docker && adduser docker staff

# Create and change app directory permissions
RUN mkdir /usr/src/app
RUN chown -R docker:docker /usr/src/app

# Bundler install gems
WORKDIR /tmp
COPY Gemfile Gemfile.lock /tmp/
# Clear bundler cache and git cache to ensure fresh fetches
# Remove any cached git gems and force fresh fetch for globalize
RUN rm -rf /usr/local/bundle/cache && \
    rm -rf /root/.bundle/cache && \
    rm -rf /usr/local/bundle/bundler/gems/globalize-* && \
    rm -rf /tmp/.bundle && \
    bundle config unset deployment && \
    bundle config set --local force_ruby_platform false && \
    bundle install -j ${BUNDLE_JOBS} --retry ${BUNDLE_RETRY} || \
    (bundle update globalize && bundle install -j ${BUNDLE_JOBS} --retry ${BUNDLE_RETRY})
# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Ensure setuid and setgid permissions are removed
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Switch to app directory and copy source
WORKDIR /usr/src/app
COPY --chown=docker:docker . /usr/src/app/

# Run bundle install again in the app directory to ensure git sources are available
# This must run as root to write to /usr/local/bundle
RUN bundle install -j ${BUNDLE_JOBS} --retry ${BUNDLE_RETRY}

# Change to docker user for remaining operations
USER docker

# Precompile assets - production only
# Clean up temp files and Yarn cache folder
RUN NODE_OPTIONS="--max-old-space-size=2048" \
    RAILS_ENV=${APP_ENV} \
    AWS_ACCESS_KEY_ID=aa00000 \
    AWS_SECRET_ACCESS_KEY=aa0000 \
    AWS_S3_BUCKET=test \
    AWS_S3_REGION=us-east-1 \
    SECRET_KEY_BASE=`bin/rails secret` \
    bundle exec rails assets:precompile --trace

# Aggressive cleanup to reduce image size
USER root
RUN rm -rf /usr/src/app/node_modules \
    && rm -rf /usr/src/app/tmp/cache/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && yarn cache clean || true \
    && npm cache clean --force || true \
    && rm -rf /root/.npm \
    && rm -rf /root/.yarn \
    && rm -rf /root/.cache \
    && rm -rf /usr/local/bundle/cache \
    && rm -rf /usr/local/bundle/bundler/gems/*/.git \
    && find /usr/local/bundle -name "*.md" -delete \
    && find /usr/local/bundle -name "*.txt" -delete \
    && find /usr/local/bundle -name "*.rdoc" -delete \
    && find /usr/local/bundle -name "*.markdown" -delete \
    && find /usr/local/bundle -name "CHANGELOG*" -delete \
    && find /usr/local/bundle -name "LICENSE*" -delete \
    && find /usr/local/bundle -name "*.gemspec" -delete \
    && find /usr/local/bundle -name "test" -type d -exec rm -rf {} + || true \
    && find /usr/local/bundle -name "spec" -type d -exec rm -rf {} + || true \
    && find /usr/local/bundle -name "*.gem" -delete \
    && apt-get purge -y build-essential || true \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /usr/share/doc \
    && rm -rf /usr/share/man \
    && rm -rf /usr/share/locale \
    && truncate -s 0 /var/log/*.log

USER docker
