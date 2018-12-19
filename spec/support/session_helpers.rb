module SessionHelpers
  def log_in
    stub_omniauth
    visit root_path
    student_wonde

    click_link 'Log In'
    expect(page).to have_content('Leo Ward')
  end

  def stub_omniauth
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:wonde] =
      OmniAuth::AuthHash.new(
        'provider' => 'wonde',
        'uid' => nil,
        'info' => {},
        'credentials' =>
         { 'token' =>
           'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6IjYyODRlNjc5NjdjZWJkMjc5YzE1MzIyMWY4MzYwYjJhMDkyYmVjMDBmYzM5OTE2MDY3ZjI5M2NhZjhjN2JkYjUwN2M0NTcyOTJmOGZkNWEzIn0.eyJhdWQiOiI2NzAxODUiLCJqdGkiOiI2Mjg0ZTY3OTY3Y2ViZDI3OWMxNTMyMjFmODM2MGIyYTA5MmJlYzAwZmMzOTkxNjA2N2YyOTNjYWY4YzdiZGI1MDdjNDU3MjkyZjhmZDVhMyIsImlhdCI6MTU0NDk1MDk3MCwibmJmIjoxNTQ0OTUwOTcwLCJleHAiOjE1NDYxNjA1NzAsInN1YiI6IjE4ODQ0Iiwic2NvcGVzIjpbXX0.i0--LjjetHyvxGfTU1nHliJwhhOWVvz0Mwj6xCQ1zeEVab9_GJkBDkY8rzautCfoF3Phwy8T36h2VBiTe38limO_anJCFOPlGYt5ajtMxdWRyQP3h5_zABzWfD7uLZGlyO6uM5BjbZG_BCKYeaQsg1ARuMx0nCcZhgiFJwa3x3NAdxLAfSoEMIGAQGxsy84JyRZW5d8exNvkM34OVgYmrc5bvYqiLYJeF9kNTBHqu9-flgx5LhmaInjJndR4U34UfmDqa308uzejelfuPHp7V2ZR6jW1iZ8kyN9pnZOXzDTLuTvV07ld3q00rQYZXpD76c0CUEouOXOUmtYVh1Z7GIAXfY6mVa6PDJUCkPH_OdkK9faz8NGx5bhHlf6rut5rp3uXDxhDxb6PpxjH935NCY2lwgsyaEmvJPGt8aU2_znBOd97fYmJ7rf6-7F79lAPG_PONLIvE4p6WCAtLZXpHaRCt_2F1yWZIchXMUIPbZi5HJp-YWZ0cjtn2FtpiDPEe0jgTvOWDK8C_rgXhjH4M3c1GR5I3kUc5oM4lZdz1l_2iHh7pmBjxqnWxmxNXtdMEK6ZCmIQgSQ-QmX6KmvJGkTgvosXN9dZimQqBf3pcplYi2jURwl288oJp5yLe_VavuK__Ey1Ta6QOaFZOzq0GZ4d3bL1KE9Xtm6F-NK_VLE',
           'refresh_token' => 'def502008f248fc2adf1a1c05b69017ef567fe0a7f5977afd7f7f58263f1f5f6407bbbbbbb4c6168e83590ff7f358f634838e95ba000f97d7b5636aaace5c1d398a699011782a73d92453a1e8219dbc0b51bb3dd1ad454ac0f6a368f7f50c86a6cac23e40b37078e0d9616d2b32f169f6335ac6e9edcbfca12d19f2ccf79028125adee97110dfc0ab188ff201f53573b75c1191c348f9d5eae4b7084d04893f8f513663c82dfdac65aef30641e55a5ef30e98ed52d18f5c6bd00e8b32dd13d9b8eb47fff9194e4370cfbf7e58f2cc4ad063497c5576a8d160d07a69b3b5588989333e4b0d6cad4840ffbbde79bca4cab067712816f6dde36b8673c0c230f11936026bf8157655b890c6972cb46bfe098c5ab67bea4574b598c32b114e1b1aff6bad69bcd65775b57fce359af17fee8de32349f425459d89e8ebb0289f51c5b3bf17bfbc66488e61bce21b749e075349eb3aabfc554a5c7c5f3053a3dff8e511677244b5c045666bf24e9',
           'expires_at' => 1_546_160_571,
           'expires' => true },
        'extra' => {}
      )
  end

  def setup_subject_database
    create(:subject_map, school: school, subject: computer_science)
    classroom = create(:classroom, school: school, subject: computer_science)
    create(:enrollment, classroom: classroom, user: student_wonde)
  end

  def setup_question_database
    setup_subject_database
    create(:multiplier)
    create(:question, topic: topic_cs)
  end

  def navigate_to_quiz
    find(class: 'subject-carousel-item-image').click
    find(:xpath, '//select').click
    find(:xpath, '//select/option[2]').click
    click_button('Create Quiz')
  end
end
