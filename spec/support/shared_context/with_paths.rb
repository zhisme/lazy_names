RSpec.shared_context 'with paths' do
  let(:project_path) { '/my/project/.lazy_names.yml' }
  let(:home_path) { '/Users/me/.lazy_names.yml' }
  let(:invalid_path) { '/dev/null/.lazy_names.yml' }
  let(:valid_path) { '/Users/my/path/.lazy_names.yml' }
end
