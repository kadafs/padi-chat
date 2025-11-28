ARG RUBY_VERSION=3.3.5
FROM ruby:${RUBY_VERSION}-slim-bullseye

ARG APP_ENV=production

ARG PG_MAJOR=15
ARG NODE_MAJOR=20
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

# Configure bundler and gem environment
ENV LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_APP_CONFIG=/usr/local/bundle \
    GEM_HOME=/usr/local/bundle \
    GEM_PATH=/usr/local/bundle

# Set PATH to include bundle bin directory for binstubs
ENV PATH=/usr/local/bundle/bin:$PATH

# Upgrade RubyGems and install required Bundler version
# Remove default bundler that comes with Ruby and install our version
# Also remove any bundler executables from system paths
# Set the installed bundler as the default
RUN gem update --system && \
    gem uninstall bundler -a -x || true && \
    rm -f /usr/local/bin/bundle /usr/local/bin/bundler || true && \
    gem install bundler:$BUNDLER_VERSION --default && \
    bundle config set --global path /usr/local/bundle && \
    bundle config set --global app_config /usr/local/bundle && \
    ln -sf /usr/local/bundle/bin/bundle /usr/local/bin/bundle || true && \
    ln -sf /usr/local/bundle/bin/bundler /usr/local/bin/bundler || true && \
    bundle --version

# Change permissions for GEM_HOME
RUN chmod -R 777 $GEM_HOME

# Add docker user
RUN adduser --disabled-password --gecos "" docker && adduser docker staff

# Create and change app directory permissions
RUN mkdir /usr/src/app
RUN chown -R docker:docker /usr/src/app

# Bundler install gems
WORKDIR /tmp
COPY Gemfile /tmp/
# Gemfile.lock will be created by bundle install if it doesn't exist
# Clear bundler cache and git cache to ensure fresh fetches
# Remove any cached git gems and force fresh fetch for globalize
# Configure bundler to use system path
RUN rm -rf /usr/local/bundle/cache && \
    rm -rf /root/.bundle/cache && \
    rm -rf /usr/local/bundle/bundler/gems/globalize-* && \
    rm -rf /tmp/.bundle && \
    bundle config unset deployment && \
    bundle config set --global path /usr/local/bundle && \
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
# Ensure bundler is configured to use the system path
RUN bundle config set --global path /usr/local/bundle && \
    bundle install -j ${BUNDLE_JOBS} --retry ${BUNDLE_RETRY}

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
    && find /usr/local/bundle -type d -name ".git" ! -path "*/bundler/gems/*" ! -path "*/ruby/*/gems/*" -exec rm -rf {} + || true \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "*.md" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "*.txt" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "*.rdoc" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "*.markdown" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "CHANGELOG*" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "LICENSE*" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "*.gemspec" -type f ! -path "*/specifications/*" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "*.gem" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "*.rb~" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name "*.orig" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name ".DS_Store" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name ".gitignore" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name ".gitattributes" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name ".travis.yml" -delete \
    && find /usr/local/bundle/ruby -maxdepth 3 -name ".github" -type d -exec rm -rf {} + || true \
    && apt-get purge -y build-essential || true \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /usr/share/doc \
    && rm -rf /usr/share/man \
    && rm -rf /usr/share/locale \
    && rm -rf /usr/share/info \
    && rm -rf /usr/share/lintian \
    && truncate -s 0 /var/log/*.log \
    && rm -rf /usr/src/app/.git || true \
    && rm -rf /usr/src/app/.github || true \
    && rm -rf /usr/src/app/spec || true \
    && rm -rf /usr/src/app/test || true

# Ensure bundler configuration is set for docker user
# Verify bundler version (gems are already installed in previous steps)
USER docker
RUN bundle config set --global path /usr/local/bundle && \
    bundle config set --global app_config /usr/local/bundle && \
    bundle --version
