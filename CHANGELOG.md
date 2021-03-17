# Change Log

## [Unreleased](https://github.com/decidim/decidim/tree/HEAD)

#### Improved menu api
As per [#7368](https://github.com/decidim/decidim/pull/7368), [#7382](https://github.com/decidim/decidim/pull/7382) the entire admin structure has been migrated from menus being rendered in partials, to the existing menu structure. Before, this change adding a new menu item to an admin submenu required partial override.

As per  [#7545](https://github.com/decidim/decidim/pull/7545) the menu api has been enhanced to support removal of elements and reordering. All the menu items have an identifier that allow any developer to interact without overriding the entire menu structure. As a result of this change, the old ```menu.item``` function has been deprecated in favour of a more verbose version ```menu.add_item ```, of which first argument is the menu identifier.

Example on adding new elements to a menu:
```ruby
Decidim.menu :menu do |menu|
  menu.add_item :root,
                I18n.t("menu.home", scope: "decidim"),
                decidim.root_path,
                position: 1,
                active: :exclusive

  menu.add_item :pages,
                I18n.t("menu.help", scope: "decidim"),
                decidim.pages_path,
                position: 7,
                active: :inclusive
end
```

Example Customizing the elements of a menu:
```ruby
Decidim.menu :menu do |menu|
  menu.remove_item :pages
  menu.move :root, after: :pages
  # alternative
  menu.move :pages, before: :root
end
```


- **Consultations module deprecation**

As the new `Votings` module is being developed and will eventually replace the `Consultations` module, the latter enters the deprecation phase.

### Added

* New Menu Api - [#7545](https://github.com/decidim/decidim/pull/7545)

### Changed

- **Authorization metadata is now encrypted in the database**

As per [\#6947](https://github.com/decidim/decidim/pull/6947), the JSON values for the authorizations' `metadata` and `verification_metadata` columns in the `decidim_authorizations` database table are now automatically encrypted because they can contain identifiable or sensitive personal information connected to a user account. Storing this data in plain text in the database would be a security risk.

You need to do changes to your code if you have been querying these tables in the past through the `Decidim::Authorization` model as follows:

```ruby
Decidim::Authorization.where(
  name: "your_authorization_handler"
).where("metadata ->> 'gender' = ?", "f").find_each do |authorization|
  puts "#{authorization.user.name} is a #{authorization.metadata["gender"]}"
end
```

The problem with this code is that the data in the `metadata ->> 'gender'` column is now encrypted, so your search would not match any records in the database. Instead, you can do the following:

```ruby
Decidim::Authorization.where(
  name: "your_authorization_handler"
).find_each do |authorization|
  next unless authorization.metadata["gender"] == "f"

  puts "#{authorization.user.name} is a #{authorization.metadata["gender"]}"
end
```

As you notice, when you are accessing the `metadata` or `verification_metadata` columns through the Active Record object, you can utilize the data in plain text. This is because the accessor method for these columns will automatically decrypt the data in the hash object.

This is less performant but it is more secure. Security weighs more.

### Fixed

### Removed

## Previous versions

Please check [release/0.24-stable](https://github.com/decidim/decidim/blob/release/0.24-stable/CHANGELOG.md) for previous changes.
