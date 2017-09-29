# ---------------------------------------------------------------
# Delete all templates books
#
InstBook.where(:template = true).destroy_all
