require 'shopify_cli'

module ShopifyCli
  module AppTypes
    class Node < AppType
      class << self
        def env_file
          <<~KEYS
            SHOPIFY_API_KEY={api_key}
            SHOPIFY_API_SECRET_KEY={secret}
            HOST={host}
            SHOP={shop}
            SCOPES={scopes}
          KEYS
        end
      end

      def self.description
        'node embedded app'
      end

      def self.serve_command(ctx)
        %W(
          HOST=#{ctx.app_metadata[:host]}
          PORT=#{ShopifyCli::Tasks::Tunnel::PORT}
          npm run dev
        ).join(' ')
      end

      def self.generate
        {
          page: 'npm run-script generate-page',
          billing_recurring: 'npm run-script generate-recurring-billing',
          billing_one_time: 'npm run-script generate-one-time-billing',
          webhook: 'npm run-script generate-webhook',
        }
      end

      def build
        ShopifyCli::Tasks::Clone.call('git@github.com:shopify/shopify-apasdfsp-node.git', name)
        ShopifyCli::Finalize.request_cd(name)
        ShopifyCli::Tasks::JsDeps.call(ctx.root)

        env_file = Helpers::EnvFile.new(
          app_type: self,
          api_key: ctx.app_metadata[:api_key],
          secret: ctx.app_metadata[:secret],
          host: ctx.app_metadata[:host],
          scopes: 'read_products',
        )
        env_file.write(ctx, '.env')

        begin
          ctx.rm_r(File.join(ctx.root, '.git'))
          ctx.rm_r(File.join(ctx.root, '.github'))
        rescue Errno::ENOENT => e
          ctx.debug(e)
        end

        puts CLI::UI.fmt(post_clone)
      end
    end
  end
end
