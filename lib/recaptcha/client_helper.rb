module Recaptcha
  module ClientHelper
    # Your public API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def recaptcha_tags(options = {})
      html  = ""
      env = options[:env] || ENV['RAILS_ENV']
      if Recaptcha.configuration.skip_verify_env.include? env
        html = <<-EOS
          <div id="recaptcha_widget_div">
            <div id="recaptcha_area" class="recaptcha_test">
              <p>Recaptcha running on test mode.</p>
              <p>Type "fail" on the field below to fail.</p>
              <p>Type any other value to pass.</p>
              <input name="recaptcha_response_field" id="recaptcha_response_field" type="text" autocorrect="off" autocapitalize="off" autocomplete="off">
            </div>
          </div>
        EOS
        return (html.respond_to?(:html_safe) && html.html_safe) || html
      end

      # Default options
      key   = options[:public_key] ||= Recaptcha.configuration.public_key
      raise RecaptchaError, "No public key specified." unless key
      error = options[:error] ||= ((defined? flash) ? flash[:recaptcha_error] : "")
      uri   = Recaptcha.configuration.api_server_url(options[:ssl])
      lang  = options[:display] && options[:display][:lang] ? options[:display][:lang].to_sym : ""
      if options[:display]
        html << %{<script type="text/javascript">\n}
        html << %{  var RecaptchaOptions = #{options[:display].to_json};\n}
        html << %{</script>\n}
      end
      if options[:ajax]
        html << <<-EOS
          <div id="dynamic_recaptcha"></div>
          <script type="text/javascript">
            var rc_script_tag = document.createElement('script'),
                rc_init_func = function(){Recaptcha.create("#{key}", document.getElementById("dynamic_recaptcha")#{',RecaptchaOptions' if options[:display]});}
            rc_script_tag.src = "#{uri}/js/recaptcha_ajax.js";
            rc_script_tag.type = 'text/javascript';
            rc_script_tag.onload = function(){rc_init_func.call();};
            rc_script_tag.onreadystatechange = function(){
              if (rc_script_tag.readyState == 'loaded' || rc_script_tag.readyState == 'complete') {rc_init_func.call();}
            };
            (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(rc_script_tag);
          </script>
        EOS
      else
        html << %{<script type="text/javascript" src="#{uri}/challenge?k=#{key}}
        html << %{#{error ? "&amp;error=#{CGI::escape(error)}" : ""}}
        html << %{#{lang ? "&amp;lang=#{lang}" : ""}"></script>\n}
        unless options[:noscript] == false
          html << %{<noscript>\n  }
          html << %{<iframe src="#{uri}/noscript?k=#{key}" }
          html << %{height="#{options[:iframe_height] ||= 300}" }
          html << %{width="#{options[:iframe_width]   ||= 500}" }
          html << %{style="border:none;"></iframe><br/>\n  }
          html << %{<textarea name="recaptcha_challenge_field" }
          html << %{rows="#{options[:textarea_rows] ||= 3}" }
          html << %{cols="#{options[:textarea_cols] ||= 40}"></textarea>\n  }
          html << %{<input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>}
          html << %{</noscript>\n}
        end
      end
      return (html.respond_to?(:html_safe) && html.html_safe) || html
    end # recaptcha_tags
  end # ClientHelper
end # Recaptcha