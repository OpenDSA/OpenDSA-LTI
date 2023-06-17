module Lti13::DeepLinkLaunchesHelper
    def deep_link_options
      {
        html_link: 'HTML Link',
        html_item: 'HTML',
        image_item: 'Image',
        lti_link: 'LTI Link',
        file_link: 'File Link'
      }
    end
  end