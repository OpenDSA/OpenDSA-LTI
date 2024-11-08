class DocumentationController < ApplicationController
  def hecvat_download
    file_path = Rails.root.join('app', 'assets', 'docs', 'HECVAT3 _OpenDSA_20220830.xlsx')
    send_file file_path, type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', disposition: 'attachment', filename: 'HECVAT3.xlsx'
  end
end