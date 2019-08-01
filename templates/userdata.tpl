#!/bin/bash
yum update -y 

cat > /tmp/gitlab.sh <<'endmsgg'

unknown_os ()
{
  echo "Unfortunately, your operating system distribution and version are not supported by this script."
  echo
  echo "You can override the OS detection by setting os= and dist= prior to running this script."
  echo "You can find a list of supported OSes and distributions on our website: https://packages.gitlab.com/docs#os_distro_version"
  echo
  echo "For example, to force CentOS 6: os=el dist=6 ./script.sh"
  echo
  echo "Please email support@packagecloud.io and let us know if you run into any issues."
  exit 1
}

curl_check ()
{
  echo "Checking for curl..."
  if command -v curl > /dev/null; then
    echo "Detected curl..."
  else
    echo "Installing curl..."
    yum install -d0 -e0 -y curl
  fi
}


detect_os ()
{
  if [[ ( -z "$${os}" ) && ( -z "$${dist}" ) ]]; then
    if [ -e /etc/os-release ]; then
      . /etc/os-release
      os=$${ID}
      if [ "$${os}" = "poky" ]; then
        dist=`echo $${VERSION_ID}`
      elif [ "$${os}" = "sles" ]; then
        dist=`echo $${VERSION_ID}`
      elif [ "$${os}" = "opensuse" ]; then
        dist=`echo $${VERSION_ID}`
      elif [ "$${os}" = "opensuse-leap" ]; then
        os=opensuse
        dist=`echo $${VERSION_ID}`
      else
        dist=`echo $${VERSION_ID} | awk -F '.' '{ print $1 }'`
      fi

    elif [ `which lsb_release 2>/dev/null` ]; then
      # get major version (e.g. '5' or '6')
      dist=`lsb_release -r | cut -f2 | awk -F '.' '{ print $1 }'`

      # get os (e.g. 'centos', 'redhatenterpriseserver', etc)
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

    elif [ -e /etc/oracle-release ]; then
      dist=`cut -f5 --delimiter=' ' /etc/oracle-release | awk -F '.' '{ print $1 }'`
      os='ol'

    elif [ -e /etc/fedora-release ]; then
      dist=`cut -f3 --delimiter=' ' /etc/fedora-release`
      os='fedora'

    elif [ -e /etc/redhat-release ]; then
      os_hint=`cat /etc/redhat-release  | awk '{ print tolower($1) }'`
      if [ "$${os_hint}" = "centos" ]; then
        dist=`cat /etc/redhat-release | awk '{ print $3 }' | awk -F '.' '{ print $1 }'`
        os='centos'
      elif [ "$${os_hint}" = "scientific" ]; then
        dist=`cat /etc/redhat-release | awk '{ print $4 }' | awk -F '.' '{ print $1 }'`
        os='scientific'
      else
        dist=`cat /etc/redhat-release  | awk '{ print tolower($7) }' | cut -f1 --delimiter='.'`
        os='redhatenterpriseserver'
      fi

    else
      aws=`grep -q Amazon /etc/issue`
      if [ "$?" = "0" ]; then
        dist='6'
        os='aws'
      else
        unknown_os
      fi
    fi
  fi

  if [[ ( -z "$${os}" ) || ( -z "$${dist}" ) ]]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="$${os// /}"
  dist="$${dist// /}"

  echo "Detected operating system as $${os}/$${dist}."
}

finalize_yum_repo ()
{
  echo "Installing pygpgme to verify GPG signatures..."
  yum install -y pygpgme --disablerepo='gitlab_gitlab-ce'
  pypgpme_check=`rpm -qa | grep -qw pygpgme`
  if [ "$?" != "0" ]; then
    echo
    echo "WARNING: "
    echo "The pygpgme package could not be installed. This means GPG verification is not possible for any RPM installed on your system. "
    echo "To fix this, add a repository with pygpgme. Usualy, the EPEL repository for your system will have this. "
    echo "More information: https://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F"
    echo

    # set the repo_gpgcheck option to 0
    sed -i'' 's/repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.repos.d/gitlab_gitlab-ce.repo
  fi

  echo "Installing yum-utils..."
  yum install -y yum-utils --disablerepo='gitlab_gitlab-ce'
  yum_utils_check=`rpm -qa | grep -qw yum-utils`
  if [ "$?" != "0" ]; then
    echo
    echo "WARNING: "
    echo "The yum-utils package could not be installed. This means you may not be able to install source RPMs or use other yum features."
    echo
  fi

  echo "Generating yum cache for gitlab_gitlab-ce..."
  yum -q makecache -y --disablerepo='*' --enablerepo='gitlab_gitlab-ce'

  echo "Generating yum cache for gitlab_gitlab-ce-source..."
  yum -q makecache -y --disablerepo='*' --enablerepo='gitlab_gitlab-ce-source'
}

finalize_zypper_repo ()
{
  zypper --gpg-auto-import-keys refresh gitlab_gitlab-ce
  zypper --gpg-auto-import-keys refresh gitlab_gitlab-ce-source
}

main ()
{
  detect_os
  curl_check


  yum_repo_config_url="https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/config_file.repo?os=$${os}&dist=$${dist}&source=script"

  if [ "$${os}" = "sles" ] || [ "$${os}" = "opensuse" ]; then
    yum_repo_path=/etc/zypp/repos.d/gitlab_gitlab-ce.repo
  else
    yum_repo_path=/etc/yum.repos.d/gitlab_gitlab-ce.repo
  fi

  echo "Downloading repository file: $${yum_repo_config_url}"

  curl -sSf "$${yum_repo_config_url}" > $yum_repo_path
  curl_exit_code=$?

  if [ "$curl_exit_code" = "22" ]; then
    echo
    echo
    echo -n "Unable to download repo config from: "
    echo "$${yum_repo_config_url}"
    echo
    echo "This usually happens if your operating system is not supported by "
    echo "packagecloud.io, or this script's OS detection failed."
    echo
    echo "You can override the OS detection by setting os= and dist= prior to running this script."
    echo "You can find a list of supported OSes and distributions on our website: https://packages.gitlab.com/docs#os_distro_version"
    echo
    echo "For example, to force CentOS 6: os=el dist=6 ./script.sh"
    echo
    echo "If you are running a supported OS, please email support@packagecloud.io and report this."
    [ -e $yum_repo_path ] && rm $yum_repo_path
    exit 1
  elif [ "$curl_exit_code" = "35" -o "$curl_exit_code" = "60" ]; then
    echo
    echo "curl is unable to connect to packagecloud.io over TLS when running: "
    echo "    curl $${yum_repo_config_url}"
    echo
    echo "This is usually due to one of two things:"
    echo
    echo " 1.) Missing CA root certificates (make sure the ca-certificates package is installed)"
    echo " 2.) An old version of libssl. Try upgrading libssl on your system to a more recent version"
    echo
    echo "Contact support@packagecloud.io with information about your system for help."
    [ -e $yum_repo_path ] && rm $yum_repo_path
    exit 1
  elif [ "$curl_exit_code" -gt "0" ]; then
    echo
    echo "Unable to run: "
    echo "    curl $${yum_repo_config_url}"
    echo
    echo "Double check your curl installation and try again."
    [ -e $yum_repo_path ] && rm $yum_repo_path
    exit 1
  else
    echo "done."
  fi

  if [ "$${os}" = "sles" ] || [ "$${os}" = "opensuse" ]; then
    finalize_zypper_repo
  else
    finalize_yum_repo
  fi

  echo
  echo "The repository is setup! You can now install packages."
}

main
endmsgg

bash /tmp/gitlab.sh

yum -y install gitlab-ce

mv /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.default

> /etc/gitlab/gitlab.rb

cat > /etc/gitlab/gitlab.rb <<'endmsg'
external_url '${user_data_gitlab_url}'

nginx['redirect_http_to_https'] = true
nginx['proxy_set_headers'] = {
  "X-Forwarded-Proto" => "http",
  "X-Forwarded-Port" => "80"
 }

nginx['real_ip_trusted_addresses'] = [ '${user_data_vpc_cidr}' ]
nginx['real_ip_header'] = 'X-Forwarded-For'
nginx['real_ip_recursive'] = 'on'
nginx['listen_port'] = 80
nginx['listen_https'] = false

# Disable the built-in Postgres
postgresql['enable'] = false

gitlab_rails['initial_root_password'] = "${user_data_gitlab_password}"

gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_encoding'] = "unicode"
gitlab_rails['db_database'] = "${user_data_db_database}"
gitlab_rails['db_username'] = "${user_data_db_username}"
gitlab_rails['db_password'] = "${user_data_db_password}"
gitlab_rails['db_host'] = "${user_data_db_host}"

redis['enable'] = false

gitlab_rails['redis_host']     = "${user_data_redis_host}"
gitlab_rails['redis_port']     = 6379
gitlab_rails['redis_password'] = "${user_data_redis_password}"
gitlab_rails['redis_ssl']      = true


endmsg

echo  "CREATE EXTENSION pg_trgm;" | PGPASSWORD=${user_data_db_password} /opt/gitlab/embedded/bin/psql -U ${user_data_db_username} -h ${user_data_db_host} -d ${user_data_db_database}
gitlab-ctl reconfigure

