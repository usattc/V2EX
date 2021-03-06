import UIKit
import SnapKit

class MemberPageViewController: BaseViewController, MemberService, AccountService {

    // MARK: - UI

    private lazy var headerView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }()

    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.setCornerRadius = 40
        return view
    }()
    
    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.boldSystemFont(ofSize: 20)
        view.textColor = .white
        return view
    }()
    
    private lazy var joinTimeLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    private lazy var followBtn: UIButton = {
        let view = UIButton()
        view.setTitle("关注", for: .normal)
        view.setTitle("已关注", for: .selected)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.setCornerRadius = 17.5
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    private lazy var blockBtn: UIButton = {
        let view = UIButton()
        view.setTitle("屏蔽", for: .normal)
        view.setTitle("已屏蔽", for: .selected)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.setCornerRadius = 17.5
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        return view
    }()

    private lazy var segmentView: UISegmentedControl = {
        let view = UISegmentedControl(items: [
            "发布的主题",
            "最近的回复"
            ])
        view.tintColor = Theme.Color.globalColor
        view.selectedSegmentIndex = 0
        view.sizeToFit()
        view.tintColor = .clear
        view.setTitleTextAttributes([
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14),
            NSAttributedStringKey.foregroundColor: UIColor.black
            ], for: .normal)
        view.setTitleTextAttributes(
            [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14),
             NSAttributedStringKey.foregroundColor: Theme.Color.globalColor
            ], for: .selected)
        view.backgroundColor = .white
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.delegate = self
        view.contentSize = CGSize(width: self.view.width * 2, height: 0)
        view.isPagingEnabled = true
        view.bounces = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    // MARK: - Propertys

    private weak var topicViewController: MyTopicsViewController?
    private weak var replyViewController: MyReplyViewController?

    public var memberName: String

    private var statusBarShouldLight = true
    private var headerViewTopConstraint: Constraint?
    private var lastOffsetY: CGFloat!

    private var member: MemberModel? {
        didSet {
            guard let `member` = member else { return }

            avatarView.setImage(urlString: member.avatarSrc, placeholder: #imageLiteral(resourceName: "avatar"))
            usernameLabel.text = member.username
            joinTimeLabel.text = member.joinTime
            headerView.image = avatarView.image
            blockBtn.isSelected = member.isBlock
            followBtn.isSelected = member.isFollow
        }
    }

    private var topics: [TopicModel] = []
    private var replys: [MessageModel] = []


    // MARK: - View Life Cycle

    init(memberName: String) {
        self.memberName = memberName
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: 手势冲突
        //        scrollView.panGestureRecognizer.require(toFail: (navigationController as! NavigationViewController).fullScreenPopGesture!)
        let topicVC = MyTopicsViewController(username: memberName)
        let replyVC = MyReplyViewController(username: memberName)
        addChildViewController(topicVC)
        addChildViewController(replyVC)
        topicViewController = topicVC
        replyViewController = replyVC
        scrollViewDidEndScrollingAnimation(scrollView)


        navBarTintColor = .white

        lastOffsetY = -200
        
        topicVC.scrollViewDidScroll = { scrollView in
            self.scrollViewDidScroll(scrollView)
        }
        
        replyVC.scrollViewDidScroll = { scrollView in
            self.scrollViewDidScroll(scrollView)
        }

        followBtn.isHidden = !AccountModel.isLogin
        blockBtn.isHidden = followBtn.isHidden

        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        navigationController?.navigationBar.shadowImage = UIImage()
        navBarBgAlpha = 0
        navigationController?.navigationBar.isTranslucent = true
//        navBarTintColor = UIColor.defaultNavBarTintColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //        navigationController?.navigationBar.shadowImage = UIImage()
        navBarBgAlpha = 0
        navigationController?.navigationBar.isTranslucent = true
        //        navBarTintColor = UIColor.defaultNavBarTintColor
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navBarBgAlpha = 1
        navigationController?.navigationBar.isTranslucent = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navBarBgAlpha = 1
        navigationController?.navigationBar.isTranslucent = false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarShouldLight ? .lightContent : .default
    }


    // MARK: - Setup
    
    override func setupSubviews() {
        view.addSubviews(headerView, segmentView, scrollView)
        headerView.addSubviews(blurView, avatarView, usernameLabel, joinTimeLabel, followBtn, blockBtn)
    }

    override func setupConstraints() {
        
        headerView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            headerViewTopConstraint = $0.top.equalToSuperview().constraint
            $0.bottom.equalTo(joinTimeLabel).offset(15)
        }

        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        avatarView.snp.makeConstraints {
            $0.left.equalToSuperview().inset(15)
            $0.top.equalTo(navigationController?.navigationBar.bottom ?? 64)
            $0.size.equalTo(80)
        }
        
        usernameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView)
            $0.top.equalTo(avatarView.snp.bottom).offset(15)
        }
        
        followBtn.snp.makeConstraints {
            $0.right.equalToSuperview().inset(15)
            $0.top.equalTo(avatarView.snp.top)
            $0.width.equalTo(75)
            $0.height.equalTo(35)
        }
        
        blockBtn.snp.makeConstraints {
            $0.right.equalTo(followBtn)
            $0.top.equalTo(followBtn.snp.bottom).offset(10)
            $0.size.equalTo(followBtn)
        }
        
        joinTimeLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView)
            $0.right.equalToSuperview().inset(15)
            $0.top.equalTo(usernameLabel.snp.bottom).offset(15)
        }

        segmentView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(headerView.snp.bottom).offset(10)
            $0.height.equalTo(44)
        }

        scrollView.snp.makeConstraints {
            $0.left.bottom.right.equalToSuperview()
            $0.top.equalTo(segmentView.snp.bottom).offset(1)
        }
    }

    override func setupRx() {
        segmentView.rx
            .controlEvent(.valueChanged)
            .subscribeNext { [weak self] in
                guard let `self` = self else { return }
                var offset = self.scrollView.contentOffset
                offset.x = self.segmentView.selectedSegmentIndex.f * self.scrollView.width
                self.scrollView.setContentOffset(offset, animated: true)
            }.disposed(by: rx.disposeBag)

        blockBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.blockUserHandle()
            }.disposed(by: rx.disposeBag)

        followBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.followUserHandle()
            }.disposed(by: rx.disposeBag)
    }
}

// MARK: - Actions
extension MemberPageViewController {

    func loadData() {
        memberHome(memberName: memberName, success: { [weak self] member, topics, replys in
            self?.topics = topics
            self?.replys = replys
            self?.member = member
        }) { error in
            log.info(error)
        }
    }

    private func blockUserHandle() {
        guard let member = member, let href = member.blockOrUnblockHref else { return }
        block(href: href, success: { [weak self] in
            self?.member?.isBlock = !member.isBlock
            HUD.showSuccess("已成功\(!member.isBlock ? "屏蔽" : "取消屏蔽")用户 \(member.username)")
        }) { error in
            HUD.showError(error)
        }
    }

    private func followUserHandle() {
        guard let member = member, let href = member.followOrUnfollowHref else { return }
        follow(href: href, success: { [weak self] in
            self?.member?.isFollow = !member.isFollow
            HUD.showSuccess("已成功\(!member.isFollow ? "关注" : "取消关注")用户 \(member.username)")
        }) { error in
            HUD.showError(error)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension MemberPageViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        guard contentOffsetY > 30 else { return }

        let showNavBarOffsetY = 200 - topLayoutGuide.length

        let delta = contentOffsetY - lastOffsetY

        let headOffset = 200 - delta


        if contentOffsetY > 200 {
            headerViewTopConstraint?.update(inset: -200)
        } else {
            headerViewTopConstraint?.update(inset: headOffset)
        }

        //navigationBar alpha
        if contentOffsetY > showNavBarOffsetY  {
            var navAlpha = (contentOffsetY - (showNavBarOffsetY)) / 40.0
            if navAlpha > 1 {
                navAlpha = 1
            }
            navBarBgAlpha = navAlpha
            if navAlpha > 0.8 {
                navBarTintColor = UIColor.defaultNavBarTintColor
                statusBarShouldLight = false
            }else{
                navBarTintColor = .white
                statusBarShouldLight = true
            }
        }else{
            navBarBgAlpha = 0
            navBarTintColor = .white
            statusBarShouldLight = true
        }
        setNeedsStatusBarAppearanceUpdate()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let index = Int(offsetX / Constants.Metric.screenWidth)

        segmentView.selectedSegmentIndex = index
        let willShowVC = childViewControllers[index]

        if willShowVC.isViewLoaded { return }
        willShowVC.view.frame = scrollView.bounds
        scrollView.addSubview(willShowVC.view)
    }


    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(scrollView)
    }
}
