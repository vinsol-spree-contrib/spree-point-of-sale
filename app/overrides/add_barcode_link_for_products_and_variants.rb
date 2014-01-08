Deface::Override.new(
  :virtual_path => 'spree/admin/products/index',
  :name => 'add print barcodes link to products for admin',
  :insert_bottom => "[data-hook='admin_products_index_row_actions']",
  :original => 'b918c38c9d3d9213d08b992cfc2c52dd0952ccf7',
  :text => %q{
    &nbsp;
    <%= link_to 'barcodes', "/admin/barcode/print_variants_barcodes/#{product.id}" %>
  }
)

Deface::Override.new(
  :virtual_path => 'spree/admin/variants/index',
  :name => 'add print barcode link to variants for admin',
  :insert_bottom => "[data-hook='variants_row'] .actions",
  :original => 'b918c38c9d3d9213d08b992cfc2c52dd0952ccf7',
  :text => %q{
    &nbsp;
    <%= link_to 'barcode', "/admin/barcode/print/#{variant.id}" %>
  }
)